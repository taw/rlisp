/*
 * #!-path must be a binary, not another #!-script
 * We need to create a small wrapper like that for RLisp to work
 */
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#ifndef RLISP_PATH
//#define RLISP_PATH "/home/taw/everything/rlisp/trunk/rlisp.rb"
#define RLISP_PATH "/usr/lib/ruby/1.8/rlisp.rb"
#endif

int main(int argc, char **argv)
{
    (void)argc;
    execvp(RLISP_PATH, argv);
    fprintf(stderr, "Cannot execute RLisp: %s\n", strerror(errno));
    return 1;
}
