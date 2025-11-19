import subprocess
import os

# Function to check if Git is installed
def check_git_installed():
    try:
        subprocess.run(["git", "--version"], check=True)
        print("Git is installed.")
    except subprocess.CalledProcessError:
        print("Git is not installed. Please install Git and try again.")
        return False
    return True

# Function to clone AutoGPT repository
def clone_autogpt(target_dir):
    git_url = "https://github.com/your-repo/AutoGPT.git"  # Replace with the actual repository URL
    if not os.path.exists(target_dir):
        os.makedirs(target_dir)
    try:
        subprocess.run(["git", "clone", git_url, target_dir], check=True)
        print(f"Successfully cloned AutoGPT into {target_dir}")
    except subprocess.CalledProcessError:
        print("Failed to clone the repository. Please check the URL or your internet connection.")

# Main function to orchestrate the setup
def setup_autogpt():
    if check_git_installed():
        target_directory = "C:\\Auto-GPT"
        clone_autogpt(target_directory)

# Run the setup function
if __name__ == "__main__":
    setup_autogpt()
