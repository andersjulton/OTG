"""
Function for parsing template Bicep files.
"""


def bicep_parser(bicep_file_path):
    param_list = []

    with open(bicep_file_path) as bicep_file, open(f'new_{bicep_file_path}', 'w') as new_file:
        lines = bicep_file.readlines()
        for i, line in enumerate(lines):
            match line.split():
                case [param, "{}"]:
                    param_list.append(f"param {param[:-1]} object")
                    n_white = len(line) - len(line.lstrip(" "))
                    new_line = f"{param} {param[:-1]}\n"
                    lines[i] = (new_line).rjust(n_white + len(new_line))
                case [param, "[", in_array, "]" | "[]"]:
                    param_list.append(f"param {param[:-1]} array")
                    n_white = len(line) - len(line.lstrip(" "))
                    new_line = f"{param} {param[:-1]}\n"
                    lines[i] = (new_line).rjust(n_white + len(new_line))
                case [param, "'string'"]:
                    param_list.append(f"param {param[:-1]} string")
                    n_white = len(line) - len(line.lstrip(" "))
                    new_line = f"{param} {param[:-1]}\n"
                    lines[i] = (new_line).rjust(n_white + len(new_line))
                case [param, ("int" | "bool" | "float") as param_type]:
                    param_list.append(f"param {param[:-1]} {param_type}")
                    n_white = len(line) - len(line.lstrip(" "))
                    new_line = f"{param} {param[:-1]}\n"
                    lines[i] = (new_line).rjust(n_white + len(new_line))
                

        [new_file.write(f"{param}\n") for param in param_list]
        new_file.write("\n")
        [new_file.write(line) for line in lines]

file_path = ""

bicep_parser(file_path)