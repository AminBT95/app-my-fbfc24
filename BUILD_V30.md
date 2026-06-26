# Build V30

Workflow inclus : `.github/workflows/build-apk.yml`.

Si GitHub Actions échoue sur PIL/Pillow, vérifier que l'étape suivante existe avant la génération icône :

```yaml
- name: Install Python dependencies
  run: |
    python3 -m pip install --upgrade pip
    python3 -m pip install Pillow
```
