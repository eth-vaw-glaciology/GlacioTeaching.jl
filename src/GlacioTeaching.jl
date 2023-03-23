module GlacioTeaching

using Literate

"""
    replace_include(str, filetype)

Replace `include`s with `@nbinclude`, useful for notebooks.

- first encounter of `include` will also add a `using NBInclude`

- `path` to work around https://github.com/stevengj/NBInclude.jl/issues/28
"""
function replace_include(str, filetype; path=nothing)
    filetype!=:nb && return str

    # regex to match include with parenthesis around
    # https://stackoverflow.com/questions/546433/regular-expression-to-match-balanced-parentheses
    re = r"\binclude\((?:[^)(]+|(?R))*+\)"

    count = 0
    out = ""
    for l in split(str, '\n')
        if occursin(re, l)
            l = replace(l, r"\binclude" => "@nbinclude")
            l = replace(l, ".jl\"" => ".ipynb\"")
            if path!==nothing
                l = replace(l, "(\"" => "(\"" * path * "/" )
            end
            if count==0
                out *= "using NBInclude\n"
            end
            count += 1
        end
        out *= l * "\n"
    end
    return out
end

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
- sub_nbinclude=true -- whether to substitute `include` with `@nbinclude` in notebooks

See also `process_folder`, which processes a whole folder of files.
"""
function process_file(fl, outputfolder, filetype=[:jl, :md, :nb][3];
                      make_outputs=[:sol, :assignment, :no_preprocessing][2 ],
                      execute=[:sol, true, false][1],
                      sub_nbinclude=true,
                      path_nbinclude=nothing,
                      flavor = Literate.CommonMarkFlavor(),
                      kws...)
    nb_sub = sub_nbinclude ? str -> replace_include(str, filetype, path=path_nbinclude) : str -> str

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

        kwargs = (credit=false, execute=ex, mdstrings=true, preprocess=nb_sub ∘ pre_fn, flavor, kws...)
        if filetype==:jl
            Literate.script(fl, outputfolder; kwargs...)
        elseif filetype==:md
            Literate.markdown(fl, outputfolder; kwargs...)
        elseif filetype==:nb
            Literate.notebook(fl, outputfolder; kwargs...)
        else
            error("Not recognized option filetype: $filetype")
        end
    end

    return nothing
end

function process_folder(inputfolder, outputfolder, filetype=[:jl, :md, :nb][3];
                        make_outputs=[:both, :sol, :assignment, :no_preprocessing][1],
                        execute=[:sol, true, false][1],
                        path_nbinclude=nothing,
                        flavor = Literate.CommonMarkFlavor(),
                        asset_files=[],
                        kws...)
    mkpath(outputfolder)

    for fl in readdir(inputfolder, join=true)
        !isfile(fl) && continue # do not recurse into sub-directories
        ext = splitext(fl)[end]
        if ext!=".jl"
            if ext in asset_files
                # copy over
                cp(fl, joinpath(outputfolder, splitdir(fl)[2]), force=true)
            end
            continue
        end
        @__FILE__() == fl && continue

        process_file(fl, outputfolder, filetype; make_outputs, execute, path_nbinclude, flavor, kws...)
    end
end

end
