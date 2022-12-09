#src # This is needed to make this run as normal Julia file:
using Markdown #src

md"""
# Excellent homework assignment

Answer the questions!
"""

# # Question 1: what is 1+1?
#hint # hint: a number between 1 and 3
#sol # It's 2!

#-

## Program a function which adds 1
#hint f(x) = ...
f(x) = 1 + x #sol

#-

## Execute this function for 1:100
#hint f.(...)
f.(1:100) #sol
