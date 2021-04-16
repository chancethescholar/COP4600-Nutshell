# COP4600-Nutshell

## Contributions:

### Chance Onyiorah: 
For this project, Chance worked on the alias section, implementing the commands `alias name word`, `unalias name`, and `alias` and accounting for alias expansion. Chance also worked on implementing the following Non-built-in commands including `ls`, `sort`, `ssh`, `nm`, `date`, `tty`, `rmdir`, `head`, `tail`, `rev`, `awk`, `less`, `tee`, and `man`. She made sure to add these commands so that they ran in the background. Chance also implemented Pipes with Non-built-in commands and both Pipes and I/O Redirection, combined, with Non-built-in Commands.

### Ishita Gupta:
For this project, Ishita worked on the environment variable section, implementing the commands `setenv variable word`, `unsetenv variable`, and `printenv` and accounting for environment variable expansion. Ishita also worked on implementing the following Non-built-in commands including `pwd`, `wc`, `cat`, `cp`, `page`, `mv`, `ping`, `echo`, `mkdir`, `rm`, `touch`, and `grep`. She made sure to add these commands so that they ran in the background. Ishita also implemented Redirecting I/O with the Non-built-in commands and wildcard matching. 

# Features

## Not Implemented:

1) Tilda Expansion
2) File name completion
3) Part of Wildcard Matching ("?" wildcard matching does not work but "*" wildcar matching does)
4) One redirecting I/O command (2>&1)

## Implemented:

1) Built-in commands: `alias name word`, `unalias name`, `alias`, `setenv variable word`, `unsetenv variable`, `printenv`, `cd`, `bye`
2) Non-built-in commands: `ls`, `sort`, `ssh`, `nm`, `date`, `tty`, `rmdir`, `head`, `tail`, `rev`, `awk`, `man`, `pwd`, `wc`, `cat`, `cp`, `page`, `mv`, `ping`, `echo`, `mkdir`, `rm`, `touch`, and `grep`. 
3) Alias expansion
4) Environment variable expansion
5) Redirecting I/O with Non-built-in Commands
6) Using Pipes with Non-built-in Commands
7) Running Non-built-in Commands in Background
8) Using both Pipes and I/O Redirection, combined, with Non-built-in Commands
9) Wildcard Matching (only works with "*" wildcard)
