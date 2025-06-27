# contianerise claude_gemini cli

step 1: build the image
```
$singularity build --remote claude.sif claude.def
```

i had to sign in to singulairty account with token before i could build remotely
it was a pain building on hpc with --fakeroot
Generate a token by signing in directly to singulairy cloud/hub `https://cloud.sylabs.io/tokens` 
run this in your terminal for option to add your token to the machin e; 
`singularity remote login`

