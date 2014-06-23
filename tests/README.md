
note: I'm too lazy to write code to make sure the second doesn't change between a few of the checks 
    which write out time as the changing data of a config.

    Thus, it's possible (though unlikely) that you'll get a failed test because the test config was written out
    in one second and the (nearly) hard coded expected results  written in the next second.

    The window for this to happen is very small.  Nevertheless, in my development and testing, I managed to get it to happen *once*.  So be aware.

If somebody was really motivated to fix it, they could consider trying to find an alternative way to test changing comments ( like maybe just manually writing them into the config).

This s a flaw with the tests, not the code.

