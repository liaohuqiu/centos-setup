some scripts for setting up centos
===========

Using root to add user to remote server:

1. create user
2. add to sudoers
3. generate ssh-key and copy that to remote server
4. Using user to initiate workspace

```
sh remote-init.sh ip-or-hostname user-name
```

Then exe the output command.

### TODO

- [ ] run the init-workspace automatically.
