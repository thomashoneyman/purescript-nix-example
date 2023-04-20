{
  eachSystem = systems: f:
    let
      isDerivation = x:
        builtins.isAttrs x && x ? type && x.type == "derivation";

      stepSystem = system: merged:
        builtins.mapAttrs (name: value:
          if !builtins.isAttrs value then
            value
          else if isDerivation value then
            (merged.${name} or { }) // { ${system} = value; }
          else
            stepSystem system (merged.${name} or { }) value);

      foldFn = attrs: system:
        let
          ret = f system;
          foldFn = attrs: key:
            attrs // {
              ${key} = (attrs.${key} or { }) // { ${system} = ret.${key}; };
            };
        in builtins.foldl' foldFn attrs (builtins.attrNames ret);
    in builtins.foldl' foldFn { } systems;
}
