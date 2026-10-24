from setuptools import setup, find_packages

setup(
    name="ma-proton",
    version="1.0.0",
    author="ma-proton contributors",
    description="Proton-equivalent Windows compatibility and translation layer for macOS",
    long_description=open("README.md", encoding="utf-8").read(),
    long_description_content_type="text/markdown",
    packages=find_packages(),
    entry_points={
        "console_scripts": [
            "ma-proton = ma_proton.cli:main",
        ],
    },
    python_requires=">=3.9",
    classifiers=[
        "Operating System :: MacOS :: MacOS X",
        "Environment :: Console",
        "Topic :: Games/Entertainment",
        "Programming Language :: Python :: 3",
    ],
)
