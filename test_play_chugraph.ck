Hid kb;
HidMsg kb_msg;

// which keyboard
0 => int device;
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
                // <<< "down:", kb_msg.which, "(code)", kb_msg.key, "(usb key)", kb_msg.ascii, "(ascii)" >>>;
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
@import {"ezScore.ck", "ScorePlayer.ck", "MyVoice.ck"}

ezScore score("sonata01-1.mid", 128, [4,4]);

ScorePlayer sp(score);

MyVoice v1;
MyVoice v2;
sp.setVoice(1, v1);     // set voice for part 1 to v1
sp.setVoice(2, v2);

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
    if(which == 29)
    {
        .1 -=> sp.rate;
        <<<"rate:", sp.rate>>>;
    }
    if(which == 27)
    {
        .1 +=> sp.rate;
        <<<"rate:", sp.rate>>>;
    }  
}

while(true)
{
    1::second => now;
}