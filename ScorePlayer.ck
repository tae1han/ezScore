@import {"ezNote.ck", "ezMeasure.ck", "ezPart.ck", "ezScore.ck", "NoteEvent.ck", "ezVoice.ck"}



public class ScorePlayer
{
    ezScore score;
    ezPart parts[];
    NoteEvent nextNotes[];

    ezVoice graphs[];

    // "subvoice" - an individual ugen in the overall voice array a subvoice
    int midi_to_subvoice[][];     // input is midi num, output is the index of which ugen is playing that note
    int subvoice_in_use[][];      // 0 if subvoice is not in use (free), 1 if subvoice is in use


    1 => float rate;
    1::ms => dur tick;
    dur tatum;
    dur playhead;


    fun ScorePlayer(ezScore s)
    {
        s @=> score;
        s.parts @=> parts;
        <<<parts.size(), "parts processed">>>;
        for(int i; i < parts.size(); i++)
        {
            cherr <= "part " <= i <= " has " <= parts[i].measures[0].notes.size() <= " notes" <= IO.newline();
        }
        new NoteEvent[parts.size()] @=> nextNotes;
        new ezVoice[parts.size()] @=> graphs;
        spork~tickDriver();

        // keep track of which subvoice we are using for each note
        new int[parts.size()][128] @=> midi_to_subvoice;        // input is midi num, output is the index of which ugen is playing that note
        for (int part; part < parts.size(); part++) {
            for (int midi; midi < 128; midi++) {
                -1 => midi_to_subvoice[part][midi];
            }
        }

        // keep track of which subvoices are currently in use
        new int[parts.size()][0] @=> subvoice_in_use;
    }

    fun void tickDriver()
    {
        // 5::second => now;   // DELETE THIS
        while(true)
        {
            tick * rate => tatum;
            tatum +=> playhead;
            // <<< playhead/ms >>>;
            for(int i; i < parts.size(); i++)
            {
                getNotesAtPlayhead(i);
            }
            tick => now;
        }
    }

    fun void pos(dur timePosition)
    {
        <<<"moving playhead to position (ms):", timePosition/ms>>>;
        timePosition => playhead;
        flushNotes();
        
    }

    fun void pos(float beatPosition)
    {
        flushNotes();
        <<<"moving playhead to position (beats):", beatPosition>>>;
        60000 / score.bpm => float ms_per_beat;
        (beatPosition * ms_per_beat)::ms => playhead;
    }

    fun void flushNotes()
    {
        for(int part; part < parts.size(); part++)
        {
            for(int subvoice; subvoice < graphs[part].n_voices; subvoice++)
            {
                graphs[part].noteOff(subvoice);
            }

            // reset whichNote indices to -1, so we know they are available for each note
            for(int j; j < 128; j++) {
                ezNote tempNote;
                j => tempNote.pitch;
                release_subvoice(part, tempNote);
            }
        }
    }

    fun void setVoice(int part, ezVoice voice)
    {
        voice @=> graphs[part];
        
        // keep track of which subvoices are currently in use
        new int[voice.n_voices] @=> subvoice_in_use[part];
    }

    fun void getNotesAtPlayhead(int partIndex)
    {
        parts[partIndex] @=> ezPart thePart;
        60000 / score.bpm => float ms_per_beat;

        ezNote currentNotes[0];

        for(int i; i < thePart.measures.size(); i++)
        {
            thePart.measures[i] @=> ezMeasure theMeasure;

            for(int j; j < theMeasure.notes.size(); j++)
            {
                theMeasure.notes[j] @=> ezNote theNote;
                theNote.onset * ms_per_beat => float theNote_onset;
                

                if(Math.fabs(theNote_onset - playhead/ms) < Math.fabs(tatum/ms))        // take abs of tatum too!!!
                {
                    //<<< "abs(onset-playhead) =",  Math.fabs(theNote_onset - playhead/ms)>>>;
                    //<<< "added note to currentNotes:", theNote_onset >>>;
                    currentNotes << theNote;
                }
            }
        }
        if(currentNotes.size() > 0)
        {
            // <<< "playing", currentNotes.size(), "note(s) at time", playhead/ms >>>;
            currentNotes @=> nextNotes[partIndex].notes;
            <<< "current notes size:", currentNotes.size()>>>;
            for(int i; i < currentNotes.size(); i++)
            {
                spork ~playNoteWrapper(partIndex, currentNotes[i]);
            }
            //nextNotes[partIndex].broadcast();
        }
    }

    fun void playNoteWrapper(int partIndex, ezNote theNote)
    {
        allocate_subvoice(partIndex, theNote) => int which_subvoice;
        graphs[partIndex].noteOn(which_subvoice, theNote);

        playhead/ms => float onset_ms;
        60000 / score.bpm => float ms_per_beat;
        theNote.beats * ms_per_beat => float duration_ms;
        Math.sgn(rate) => float direction;

        while((playhead/ms - onset_ms)*direction < duration_ms) 
        {
            tick => now;
        }

        graphs[partIndex].noteOff(which_subvoice);
        release_subvoice(partIndex, theNote);
    }

    // Gets the subvoice index of the note. If the note doesn't have a subvoice, allocates a new one and returns the index
    fun int allocate_subvoice(int partIndex, ezNote theNote)
    {
        midi_to_subvoice[partIndex][theNote.pitch] => int cur_subvoice_index;

        // If the note doesn't have a subvoice, allocate one!
        if (cur_subvoice_index == -1) {
            get_free_subvoice(partIndex) => int free_subvoice_index;                // find a free subvoice for the note
            if (free_subvoice_index == -1)      // if there are no free subvoices, free one at random
            {
                Math.random2(0, graphs[partIndex].n_voices) => free_subvoice_index;
                // ezNote tempNote;
                // release_subvoice()  // we might have to create subvoice_to_midi instead of subvoice_in_use...
            }
            free_subvoice_index => midi_to_subvoice[partIndex][theNote.pitch];      // map the note to it's new subvoice
            1 => subvoice_in_use[partIndex][free_subvoice_index];                   // marking the new subvoice as in use
            return free_subvoice_index;
        }

        return cur_subvoice_index;
    }

    // Helper for grab_subvoice(). Returns the lowest index of a free subvoice for a given part (or random index if there are no free subvoices).
    fun int get_free_subvoice(int partIndex)
    {
        graphs[partIndex].n_voices => int n_voices;
        int free_subvoice_index;                        
        for (int i; i < n_voices; i++) {
            if (subvoice_in_use[partIndex][i] == 0) {
                return i;
            }
        }
        // if none are free return -1
        return -1;
    }

    // Releases the subvoice that was in use for a specific note
    fun void release_subvoice(int partIndex, ezNote theNote)
    {
        midi_to_subvoice[partIndex][theNote.pitch] => int subvoice_to_release;
        if (subvoice_to_release == -1) return;      // if the subvoice is already released, no need to release it again

        // otherwise, release the subvoice
        -1 => midi_to_subvoice[partIndex][theNote.pitch];
        0 => subvoice_in_use[partIndex][subvoice_to_release];
    }
}

