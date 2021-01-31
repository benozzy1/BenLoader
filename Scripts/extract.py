import zipfile
import sys
#total arguments
arguments_count = len(sys.argv)
if arguments_count > 3:
    print("Too many arguments!")
    exit()
elif arguments_count < 2:
    print("Too little arguments!")
    exit()

from_path = sys.argv[1]
to_path = sys.argv[2]
with zipfile.ZipFile(from_path, 'r') as zip_ref:
    result = zip_ref.extractall(to_path)
os.remove(from_path)

print("Finished extracting!")
