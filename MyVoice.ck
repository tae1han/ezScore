public class MyVoice extends ezVoice
{
    // define sound chain
    8 => n_voices;
    SinOsc oscs[n_voices]; 
    ADSR envs[n_voices]; 
    Gain g => NRev rev => dac;
    g.gain(.1);
    rev.mix(.01);
    for(int i; i < n_voices; i++)
    {
        oscs[i] => envs[i] => g;
        envs[i].set(20::ms, 7000::ms, 0.0, 120::ms);
    }

    fun void noteOn(int which, ezNote theNote)
    {
        Std.mtof(theNote.pitch) => oscs[which].freq;
        theNote.velocity / 127.0 => oscs[which].gain;
        envs[which].keyOn();
    }

    fun void noteOff(int which)
    {
        envs[which].keyOff();
    }
}

