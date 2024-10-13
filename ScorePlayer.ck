public class ScorePlayer
{
    ezScore score;
    ezPart parts[];
    NoteEvent nextNotes[];

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
    }

    fun void update()
    {
        tick * rate => tatum;
        tatum +=> playhead;
        // getNotesAtPlayhead(1);
        for(int i; i < parts.size(); i++)
        {
            getNotesAtPlayhead(i);
        }
    }

    fun void tickDriver()
    {
        while(true)
        {
            update();
            tick => now;
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
                if(Math.sgn(theNote_onset - playhead/ms) * (theNote_onset - playhead/ms) < tatum/ms)
                {
                    currentNotes << theNote;
                }
            }
        }
        if(currentNotes.size() > 0)
        {
            // <<< "playing", currentNotes.size(), "note(s) at time", playhead/ms >>>;
            currentNotes @=> nextNotes[partIndex].notes;
            nextNotes[partIndex].signal();
        }
    }
}

