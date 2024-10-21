public class ScorePlayer
{
    ezScore score;
    ezPart parts[];
    NoteEvent nextNotes[];

    ezVoice graphs[];

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
    }

    fun void tickDriver()
    {
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
        flushNotes();
        timePosition => playhead;
    }

    fun void pos(float beatPosition)
    {
        flushNotes();
        60000 / score.bpm => float ms_per_beat;
        (beatPosition * ms_per_beat)::ms => playhead;
    }

    fun void flushNotes()
    {
        for(int i; i < parts.size(); i++)
        {
            for(int j; j < graphs[i].n_voices; j++)
            {
                graphs[i].noteOff(j);
            }
        }
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
            for(int i; i < currentNotes.size(); i++)
            {
                spork ~playNoteWrapper(partIndex, i, currentNotes[i]);
            }
            //nextNotes[partIndex].broadcast();
        }
    }

    fun void playNoteWrapper(int partIndex, int whichNote, ezNote theNote)
    {
        graphs[partIndex].noteOn(whichNote, theNote);

        playhead/ms => float onset_ms;
        60000 / score.bpm => float ms_per_beat;
        theNote.beats * ms_per_beat => float duration_ms;
        Math.sgn(rate) => float direction;

        while((playhead/ms - onset_ms)*direction < duration_ms) 
        {
            tick => now;
        }

        graphs[partIndex].noteOff(whichNote);
    }
}

