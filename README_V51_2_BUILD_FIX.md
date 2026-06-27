# V51.2 Build Fix

Corrections build après le log GitHub Actions :

- Correction de la parenthèse/structure dans `ReportsSavedTab` / `ProBox`.
- Remplacement des getters inexistants `p.pace`, `p.shooting`, `p.passing`, `p.dribbling`, `p.defending`, `p.physical` par `p.s['pac']`, `p.s['sho']`, etc.
- Correction des ternaires Dart invalides `condition?.62:.38` vers `condition ? .62 : .38`.
- Version bump : `1.0.512+512`.
- Workflow GitHub Actions conservé avec installation Pillow.
