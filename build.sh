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
PACKAGE_PATH="$SCRIPT_PATH/build"

if [[ -d "$PACKAGE_PATH" ]]; then
  rm -rf "$PACKAGE_PATH"
fi

mkdir "$PACKAGE_PATH"
mkdir "$PACKAGE_PATH/bin"
cp -R -P "$SCRIPT_PATH/src/"* "$PACKAGE_PATH/bin"

mkdir "$PACKAGE_PATH/lib"

PY_HOME=$(python -c 'import sys;print(sys.base_prefix)')
PY_VER=$(basename $(ls -d $PY_HOME/lib/python*.*))

cp -R -P "$PY_HOME/lib/$PY_VER" "$PACKAGE_PATH/lib/"
cp "$PY_HOME/Python" "$PACKAGE_PATH/libpython.dylib"

# Some files in the Python system lib point to this one, so we recreate it as a symlink.
ln -s "libpython.dylib" "$PACKAGE_PATH/Python"

# We're going to replace the system site-packages with the one from the virtual env.
rm -rf "$PACKAGE_PATH/lib/$PY_VER/site-packages"
# The test package is only for Python internal testing, no need to ship.
rm -rf "$PACKAGE_PATH/lib/$PY_VER/test"
rm -rf "$PACKAGE_PATH/lib/$PY_VER/lib2to3"

cp -R -P "$VENV_PATH/lib/$PY_VER/site-packages" "$PACKAGE_PATH/lib/$PY_VER/"

echo Compiling sources...

python -m compileall -q -b "$PACKAGE_PATH"

find "$PACKAGE_PATH" -type f -name "*.py" -delete
find "$PACKAGE_PATH" -type f -name "*.o" -delete
find "$PACKAGE_PATH" -type d -name "__pycache__" | xargs rm -rf

echo Packaged into $PACKAGE_PATH
