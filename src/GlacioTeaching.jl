module GlacioTeaching

using Literate

"""
    process_hashtag(str, hashtag, fn; striptag=true)

Process all lines in str which start or end with a hashtag with the supplied
function `fn` (`line->newline`).

Notes:
- hashtag needs to be of form `#xyz` where `xyz` is a string with no whitespace-chars
- indentation is preserved during processing
- if the hashtag starts a line it has to be separated from the rest of the line with at least
  one whitespace. One whitespace after the hashtag is also removed.

```
# drop lines starting or ending with "#sol"
drop_sol = str -> process_hashtag(str, "#sol", line -> "")
Literate.notebook(fl, "notebooks", preproces=drop_sol)
```
"""
function process_hashtag(str, hashtag, fn; striptag=true)
    occursin("\r\n", str) && error("""DOS line endings "\r"n" not supported""")
    any((isspace(h) for h in hashtag)) && error("""`hashtag` cannot contain whitespace""")


    out = ""
    regex = Regex(hashtag)
    for line in split(str, '\n')
        # turn `line` into String, then strip whitespace; that way the returned substring has
        # info on removed whitespace to be re-inserted later (we only care about preceeding whitespace).
        line = lstrip(string(rstrip(line)))
        leading_whitespace = line.string[1:line.offset]

        line_processed =false

        line = if startswith(line, hashtag*" ") # a hashtag starting the line needs to be followed by a space
            line_processed = true
            fn(striptag ? replace(line, hashtag*" "=>"") : line)
        elseif endswith(line, hashtag)
            line_processed = true
            fn(striptag ? replace(line, hashtag=>"") : line)
        else
            line
        end
        # only re-add processed line if there is something left of the line
        if !(line_processed && length(line)==0)
            out *= leading_whitespace * line  * "\n" # re-add leading whitespace and re-add newline as that gets stripped by loop-iterator
        end
    end
    return out
end

"Use as `preproces` function to remove `#sol`-lines & just remove `#hint`-tag"
function make_hint(str)
    str = process_hashtag(str, "#sol", line->"")
    str = process_hashtag(str, "#hint", line->line) # re-add the newline
    return str
end
"Use as `preproces` function to remove `#hint`-lines & just remove `#sol`-tag"
function make_sol(str)
    str = process_hashtag(str, "#sol", line->line) # re-add the newline
    str = process_hashtag(str, "#hint", line->"")
    return str
end

"""
    function process_file(fl, outputfolder, filetype=[:jl, :md, :nb][3];
                          make_outputs=[:sol, :assignment, :no_preprocessing][2],
                          execute=[:sol, true, false][1])

Process one Julia-Literate-file and stick it into the outputfolder.  It can process files
which have special tags `#sol` and `#hint` which will be rendered depending on what kind
of output is used.

The `filetype` determines what output is done: a julia-script, markdown, or Jupyter-notebook

Options:
- make_outputs=[:sol, :assignment, :no_preprocessing][2] -- which output should be produced.
- execute=[:sol, true, false][1] -- whether to run the script or not. `:sol` only runs when
                                    producing a "solution" file.

See also `process_folder`, which processes a whole folder of files.
"""
function process_file(fl, outputfolder, filetype=[:jl, :md, :nb][3];
                      make_outputs=[:sol, :assignment, :no_preprocessing][2 ],
                      execute=[:sol, true, false][1])
    # create ipynb and scripts
    pre_fns = if make_outputs==:both
        [make_sol, make_hint]
    elseif make_outputs==:sol
        [make_sol]
    elseif make_outputs==:assignment
        [make_hint]
    elseif make_outputs==:no_preprocessing
        x->x
    else
        error("Kwarg `make_outputs` not recognised: $make_outputs")
    end


    for pre_fn in pre_fns
        ex = if execute==:sol
            pre_fn==make_sol ? true : false
        else
            execute
        end

        if filetype==:jl
            Literate.script(fl, outputfolder; credit=false, execute=ex, mdstrings=true, preprocess=pre_fn)
        elseif filetype==:md
            Literate.markdown(fl, outputfolder; credit=false, execute=ex, mdstrings=true, preprocess=pre_fn)
        elseif filetype==:nb
            Literate.notebook(fl, outputfolder; credit=false, execute=ex, mdstrings=true, preprocess=pre_fn)
        else
            error("Not recognized option filetype: $filetype")
        end
    end

    return nothing
end

function process_folder(inputfolder, outputfolder, filetype=[:jl, :md, :nb][3];
                        make_outputs=[:both, :sol, :assignment, :no_preprocessing][1],
                        execute=[:sol, true, false][1]
                        )

    mkpath(outputfolder)

    for fll in readdir(inputfolder)
        if splitext(fll)[end]!=".jl" || splitpath(@__FILE__)[end]==fll
            continue
        end
        fl = joinpath(inputfolder, fll)

        println("Processing file: $fl")

        process_file(fl, outputfolder, filetype; make_outputs, execute)
    end
end

end
