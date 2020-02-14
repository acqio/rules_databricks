
# Copied from https://github.com/bazelbuild/bazel-skylib/blob/master/lib/dicts.bzl
# Remove it if we add a dependency on skylib.
def _add_dicts(*dictionaries):
    """Returns a new `dict` that has all the entries of the given dictionaries.
    If the same key is present in more than one of the input dictionaries, the
    last of them in the argument list overrides any earlier ones.
    This function is designed to take zero or one arguments as well as multiple
    dictionaries, so that it follows arithmetic identities and callers can avoid
    special cases for their inputs: the sum of zero dictionaries is the empty
    dictionary, and the sum of a single dictionary is a copy of itself.
    Args:
      *dictionaries: Zero or more dictionaries to be added.
    Returns:
      A new `dict` that has all the entries of the given dictionaries.
    """
    result = {}
    for d in dictionaries:
        result.update(d)
    return result

def _list_to_string(string_list):
    result=[]
    for l in string_list:
      result.append("'" + str(l) + "'")
    return ' '.join(result)

def _merge_runfiles(ctx, runfiles, srcs):
    return runfiles.merge(ctx.runfiles(files = srcs))

def _tpl_command(program, options, args):
    return "python %s %s %s;" % (program, options, args)

utils = struct(
    add_dicts = _add_dicts,
    list_to_string = _list_to_string,
    runfiles = _merge_runfiles,
    tpl_command = _tpl_command,
)

def join(directory, path):
    """Compute the relative data path prefix from the data_path attribute.
    Args:
      directory: The relative directory to compute path from
      path: The path to append to the directory
    Returns:
      The relative data path prefix from the data_path attribute
    """
    if not path:
        return directory
    if path[0] == "/":
        return path[1:]
    if directory == "/":
        return path
    return directory + "/" + path


def join_path(directory, path):
    """Compute the relative data path prefix from the data_path attribute.
    Args:
      directory: The relative directory to compute path from
      path: The path to append to the directory
    Returns:
      The relative data path prefix from the data_path attribute
    """
    if directory.startswith("/"):
        directory = directory[1:]
    elif not directory.endswith("/"):
        directory = directory + "/"
    else:
        directory = directory

    if path.startswith("/"):
        path = path[1:]
    elif not path.endswith("/"):
        path = path + "/"
    else:
        path = path

    return directory + path

def dirname(path):
    """Returns the directory's name.
    Args:
      path: The path to return the directory for
    Returns:
      The directory's name.
    """
    last_sep = path.rfind("/")
    print (last_sep)
    if last_sep == -1:
        return ""
    print(path[:last_sep])
    return path[:last_sep]

def resolve_stamp(ctx, string, output):
    stamps = [ctx.info_file, ctx.version_file]
    args = ctx.actions.args()
    args.add_all(stamps, format_each = "--stamp-info-file=%s")
    args.add(string, format = "--format=%s")
    args.add(output, format = "--output=%s")
    ctx.actions.run(
        executable = ctx.executable._stamper,
        arguments = [args],
        inputs = stamps,
        tools = [ctx.executable._stamper],
        outputs = [output],
        mnemonic = "Stamp",
    )
