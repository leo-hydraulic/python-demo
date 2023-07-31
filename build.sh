set -e

SCRIPT_PATH=$(dirname "$(readlink -f $0)")
VENV_PATH=$SCRIPT_PATH/venv

PYTHON=${PYTHON:-python3}
PYVER=$("$PYTHON" --version)

echo Using "$PYVER"

if [[ ! -d "$VENV_PATH" ]]; then
  echo Creating virtual environment...
  "$PYTHON" -m venv "$VENV_PATH"
fi

source "$VENV_PATH/bin/activate"
trap 'deactivate' EXIT

VENV_PYVER=$(python --version)
if [[ "$PYVER" != "$VENV_PYVER" ]]; then
  echo "Version of the virtual environment ($VENV_PYVER) differs from Python used for running the script ($PYVER)."
  echo "You probably want to erase '$VENV_PATH'"
  exit 1
fi

echo Installing requirements...

python -m pip install --upgrade pip
python -m pip install -r "$SCRIPT_PATH/requirements.txt"

echo Preparing package...
python -m pip install pyinstaller
pyinstaller -w --workpath "${SCRIPT_PATH}/build" --distpath "${SCRIPT_PATH}/dist" "${SCRIPT_PATH}/src/main.py"

echo Packaged into "${SCRIPT_PATH}/dist"
