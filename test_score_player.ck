// Hid trak;
// HidMsg trak_msg;

// // which keyboard
// 0 => int trak_device;

// // z axis deadzone
// 0.007 => float DEADZONE;

// // open joystick 0, exit on fail
// if( !trak.openJoystick( trak_device ) ) me.exit();

// // print
// <<< "joystick '" + trak.name() + "' ready", "" >>>;

// // data structure for gametrak
// class GameTrak
// {
//     // timestamps
//     time lastTime;
//     time currTime;
    
//     // previous axis data
//     float lastAxis[6];
//     // current axis data
//     float axis[6];
// }

// // gametrack
// GameTrak gt;

// // spork control
// spork ~ gametrak();

// // gametrack handling
// fun void gametrak()
// {
//     while( true )
//     {
//         // wait on HidIn as event
//         trak => now;
        
//         // messages received
//         while( trak.recv( trak_msg ) )
//         {
//             // <<< "axes:", gt.axis[0],gt.axis[1],gt.axis[2], gt.axis[3],gt.axis[4],gt.axis[5]>>>;
//             // joystick axis motion
//             if( trak_msg.isAxisMotion() )
//             {
//                 // check which
//                 if( trak_msg.which >= 0 && trak_msg.which < 6 )
//                 {
//                     // check if fresh
//                     if( now > gt.currTime )
//                     {
//                         // time stamp
//                         gt.currTime => gt.lastTime;
//                         // set
//                         now => gt.currTime;
//                     }
//                     // save last
//                     gt.axis[trak_msg.which] => gt.lastAxis[trak_msg.which];
//                     // the z axes map to [0,1], others map to [-1,1]
//                     if( trak_msg.which != 2 && trak_msg.which != 5 )
//                     { trak_msg.axisPosition => gt.axis[trak_msg.which]; }
//                     else
//                     {
//                         1 - ((trak_msg.axisPosition + 1) / 2) - DEADZONE => gt.axis[trak_msg.which];
//                         if( gt.axis[trak_msg.which] < 0 ) 0 => gt.axis[trak_msg.which];
//                     }
//                 }
//             }

//         }
//     }
// }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


ezScore score;
score.setTempo(128);
score.setTimeSig(4, 4);
score.importMIDI("sonata01-1.mid");

ScorePlayer sp(score);

spork~sp.tickDriver();
spork~part1();
// spork~part2();

fun void part1()
{
    8 => int n_voices;
    SinOsc osc[n_voices]; 
    ADSR env[n_voices]; 
    Gain g => NRev rev => dac;
    g.gain(.8);
    rev.mix(.05);
    for(int i; i < n_voices; i++)
    {
        osc[i] => env[i] => g;
        osc[i].gain(1.0);
        env[i].set(50::ms, 800::ms, 0.0, 100::ms);
    }

    while(true)
    {
        sp.nextNotes[1] => now;
        <<< "Playing", sp.nextNotes[1].notes.size(), "note(s) at", sp.playhead >>>;
        sp.nextNotes[1].notes @=> ezNote currentNotes[];
        for(int i; i < currentNotes.size(); i++)
        {
            Std.mtof(currentNotes[i].pitch) => osc[i].freq;
            env[i].keyOn();
        }
    }
}

fun void part2()
{
    8 => int n_voices;
    TriOsc osc[n_voices]; 
    ADSR env[n_voices]; 
    Gain g => NRev rev => dac;
    g.gain(.8);
    rev.mix(.05);
    for(int i; i < n_voices; i++)
    {
        osc[i] => env[i] => g;
        osc[i].gain(1.0);
        env[i].set(50::ms, 800::ms, 0.0, 100::ms);
    }

    while(true)
    {
        sp.nextNotes[2] => now;
        <<< "Playing", sp.nextNotes[2].notes.size(), "note(s) at", sp.playhead >>>;
        sp.nextNotes[2].notes @=> ezNote currentNotes[];
        for(int i; i < currentNotes.size(); i++)
        {
            Std.mtof(currentNotes[i].pitch) => osc[i].freq;
            env[i].keyOn();
        }
    }
}

// fun void changeRate()
// {
//     while(true)
//     {
//         gt.axis[3]*2.0 => sp.rate;
//         1::second => now;
//     }
// }

//spork~changeRate();

while(true)
{
    1::second => now;
}