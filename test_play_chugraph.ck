Hid kb;
HidMsg kb_msg;

// which keyboard
3 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open keyboard (get device number from command line)
if( !kb.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + kb.name() + "' ready", "" >>>;

// infinite event loop
fun void kb_listener()
{
    while( true )
    {
        // wait on event
        kb => now;

        // get one or more messages
        while( kb.recv( kb_msg ) )
        {
            // check for action type
            if( kb_msg.isButtonDown() )
            {
                <<< "down:", kb_msg.which, "(code)", kb_msg.key, "(usb key)", kb_msg.ascii, "(ascii)" >>>;
                kb_set_playhead(kb_msg.which);
                kb_set_rate(kb_msg.which);
            }
            
            else
            {
                //<<< "up:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;
            }
        }
    }
}
spork ~ kb_listener();

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


ezScore score;
score.setTempo(128);
score.setTimeSig(4, 4);
score.importMIDI("sonata01-1.mid");

ScorePlayer sp(score);

MyVoice v1;
MyVoice v2;
v1 @=> sp.graphs[1];
v2 @=> sp.graphs[2];

fun void kb_set_playhead(int which)
{
    if (which == 39) 
    {
        <<<"0 pressed">>>;
        sp.pos(20.0);
    }
}

fun void kb_set_rate(int which)
{
    if(which == 80)
    {
        .1 -=> sp.rate;
        <<<"rate:", sp.rate>>>;
    }
    if(which == 79)
    {
        .1 +=> sp.rate;
        <<<"rate:", sp.rate>>>;
    }  
}

while(true)
{
    1::second => now;
}