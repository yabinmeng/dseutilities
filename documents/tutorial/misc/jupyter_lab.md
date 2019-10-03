# Overview

This document describes how to set up a [Jupyter](https://jupyter.org/) Lab (server) on a remote host. The procedure is tested out on a remote machine with Ubuntu Xenial (16.04.3 LTS) OS.

## Install Jupyter via Anaconda 

There are different ways of installing Jupyter notebook, but the easiest way is through [Anaconda](https://www.anaconda.com/). The procedure is as below:

1) Download the right version of Anaconda installation script (e.g. Python 2.7 vs 3.7; Windows/Mac OS/Linux)
```
$ wget https://repo.anaconda.com/archive/Anaconda2-2019.07-Linux-x86_64.sh
```

2) Create a home directory for Anaconda to be installed
```
$ sudo mkdir -p /opt/anaconda2
$ sudo chown -R <user>:<user> /opt/anaconda2
```

3) Execute the installation script
```
$ chmod +x Anaconda2-2019.07-Linux-x86_64.sh
$ ./Anaconda2-2019.07-Linux-x86_64.sh -u
```

Follow the instructions on the screen and make sure to use the directory created in step 2) as the home directory for Anaconda2, which requires "-u" option of the script being provided.

After the installation completes, close and re-open the current Linux shell in order to make effective of Anaconda environment. 

The installation script will install many Python/R packages which includes Jupyter as well. In order to verify whether Jupyter is installed, we can run the following command

```
$ (base) $ which jupyter
/opt/anaconda2/bin/jupyter

(base) $ jupyter --version
jupyter core     : 4.5.0
jupyter-notebook : 5.7.8
qtconsole        : 4.5.1
ipython          : 5.8.0
ipykernel        : 4.10.0
jupyter client   : 5.3.1
jupyter lab      : 0.33.11
nbconvert        : 5.5.0
ipywidgets       : 7.5.0
nbformat         : 4.4.0
traitlets        : 4.3.2
```

## Install Iris Package

[Iris] (https://scitools.org.uk/iris/docs/latest/) is a powerful, format-agnostic Python library for analyzing multi-dimensional data such as Earth data. In one of the tests, we're going to use it. But the (default) Anaconda installation doesn't include this package and therefore we need to install it manually. The command is as below
```
(base) $ which conda
/opt/anaconda2/bin/conda

(base) $ conda install -c conda-forge iris
```

Follow the instructions on the screen and once the installation completes, we can verify whether the package is installed using the following command and then verify that "Iris" package is in the list.
```
(base) $ conda list
```


# Configure Jupyter Lab

Once installed successfully, we can start Jupyter Lab by running the following commands:
```
$ jupyter lab  
```

However, the limitation here is it the started Jupyter Lab only listens on port **<localhost>:8888**, which means we can only access the Lab locally. For remote access, we need to make some configuration changes.

First, we need to create a default configuration file. The command below creates a default configuration file, **~/.jupyter/jupyter_notebook_config.py**, with all configuration settings commented out.
```
$ jupyter notebook --generate-config
```

Second, depending on the requirements, we need to enable and tune the parameters in this file accordingly. For our testing purpose, we want to achieve the following functionalities:
* Allow remote access to Jupyter Lab
* listens on a port that is not default (which is 8888)
* Needs password protection when accessing Jupyter Lab

In order to achieve the above requirements, we need to make the following settings in the configuration file:
```
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.port = 9999
c.NotebookApp.password = u'sha1:b75fb86b08ed:74e0d07a3d349b42e22e33f3f405fb472ec03021'
```

Please note that the password string is a hashed password string that is generated using the following command:
```
$ jupyter notebook password
Enter password:  <raw_password_string>
Verify password: <raw_password_string>
[NotebookPasswordApp] Wrote hashed password to <user_home_dir>/.jupyter/jupyter_notebook_config.json
```

After file **jupyter_notebook_config.json** is created, copy the hashed password string and used in the main configuration file. 

## Start Jupyter Lab and Access its Web UI

After making all necessary configuration settings, start Jupyter Lab using the following command:
```
$ jupyter lab
```

After the Jupyter Lab is started, access its Web UI from the following URL: http://<remote_node_ip>:9999. The landing page requires to enter the password (as per our configuration).