// Copyright 2021 Aspect Build
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

use std::env;
use std::fs;
use std::process;

// PYTHON3 is the name of the program to be executed relative to where this
// program got executed. This is not a relative path to the working directory.
// On different platforms, there are different strategies for determining the
// real path of the executable, e.g. on Linux we use /proc/self/exe.
static PYTHON3: &str = "python3";

fn main() {
    let pythonbin = if cfg!(target_os = "linux") {
        let selfpath = fs::canonicalize("/proc/self/exe").unwrap();
        let selfdir = selfpath.parent().unwrap();
        String::from(selfdir.join(PYTHON3).to_str().unwrap())
    } else {
        // Not implemented yet.
        process::exit(1);
    };

    let selfargs: Vec<String> = env::args().collect();
    let args = selfargs[1..selfargs.len()].to_vec();
    process::exit(process::Command::new(pythonbin)
            .args(args)
            .stdin(process::Stdio::inherit())
            .env("PYTHONNOUSERSITE", "1")
            .status().unwrap()
            .code().unwrap());
}
