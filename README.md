# contianerise claude_gemini cli

step 1: build the image
```
$singularity build --remote claude.sif claude.def
```

i had to sign in to singulairty account with token before i could build remotely

It was a pain building on hpc with --fakeroot;
Generate a token by signing in directly to singulairy cloud/hub `https://cloud.sylabs.io/tokens` 

Run this in your terminal for option to add your token to the machine; 
```
singularity remote login
```

To run 
```
singularity exec claude.sif claude
```