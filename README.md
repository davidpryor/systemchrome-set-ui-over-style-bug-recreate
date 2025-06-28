
### Recreate the issue with SystemChrome.setSystemUIOverlayStyle being overwritten by internal flutter code
#### 3 Scenarios:
1. (No AppBar - No Post Frame Callback)

    SystemChrome.setSystemUIOverlayStyle is called before the Material/Cupertino app is built
    
    This will cause the internal style to be applied because `setSystemUIOverlayStyle` takes
    the payload of the LAST call to `setSystemUIOverlayStyle` before the platform call is dispatched.

    `fvm/versions/3.32.5/packages/flutter/lib/src/services/system_chrome.dart:712`
2. (AppBar - No SystemOverlayStyle - No Post Frame Callback)

    Scaffolding uses an appbar WITHOUT the systemOverlayStyle set AND no post frame callback
    
    This will lead to the call order of 'developers set style' -> "MaterialApp set style" -> "view renderer set style"
    which causes the initial user set nav bar style to not be changeable (persist the last set nav bar style)

    `fvm/versions/3.32.5/packages/flutter/lib/src/rendering/view.dart:487`
3. (Postframe Callback)

    Calling SystemChrome.setSystemUIOverlayStyle after the MaterialApp has been built
    
    This allows the developer set style to be applied after the MaterialApp has set its own style,
    which is necessary to ensure the developer's style is not overwritten by the MaterialApp's
    internal style.
