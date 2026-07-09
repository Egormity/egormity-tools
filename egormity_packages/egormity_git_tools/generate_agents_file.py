def generate(info):
    lines = []
    lines.append(f"# {info['name']} Workspace Agent Navigation\n")
    lines.append("## Multi-project container\n")

    for i, r in enumerate(info["repos"], 1):
        lines.append(f"{i}. {r['name']} => {r['link']}")

    return "\n".join(lines)

def write(info, output_folder=".", filename="AGENTS.md"):
    import os
    os.makedirs(output_folder, exist_ok=True)

    path = os.path.join(output_folder, filename)
    with open(path,"w",encoding="utf-8") as f:
        f.write(generate(info))

    return path