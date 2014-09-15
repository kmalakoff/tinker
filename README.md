tinker
======

Tinker with your bower and node modules!

Why
------

I often find myself editing modules directly in node_modules or bower_components. When I'm done, I need to merge my changes back into a library repo or to revert to a released state.

Tinker provides some easy mechanisms to switch back and forth between modules installed from your favorite package manager and a git repo.


Getting Started
------

1. Install

```
$ npm install tinker -g
```

2. Initialize

```
project$ tinker init
```

3. Start tinkering! (copy .git folder or git clone)

```
project$ tinker on module_name
project$ tinker on 'start_of_name*'
```

Prompts will help you protect your work.

4. Execute commands on your modules

```
project$ tinker module_name gulp watch
project$ tinker module_name git status
project$ tinker module_name gulp test; gulp watch
```

5. Stop tinkering! (remove .git folder or clean install)

```
project$ tinker off module_name
```
