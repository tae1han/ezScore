@import {"../src/ezScore.ck", "../src/ScorePlayer.ck", "../src/MyVoice.ck"}

ezScore score("../media/sonata01-1.mid", 128, [4,4]);
ScorePlayer sp(score);

MyVoice v1;
MyVoice v2;
sp.setVoice(0, v1);
sp.setVoice(1, v2);


while(true)
{
    1::second => now;
}