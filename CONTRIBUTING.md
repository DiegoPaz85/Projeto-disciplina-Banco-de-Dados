# Como contribuir

## 🌿 Fluxo de trabalho

1. **Crie uma branch** para cada mudança:
   ```bash
   git checkout -b feat/nome-da-mudanca
   ```

2. **Faça commits pequenos e descritivos:**
   ```bash
   git add arquivo.py
   git commit -m "fix: corrige extração do DDL quando Projeto.txt está vazio"
   ```

3. **Push e Pull Request:**
   ```bash
   git push origin feat/nome-da-mudanca
   ```
   Depois abra PR no GitHub.

## 📝 Convenção de mensagens de commit

Use prefixos (Conventional Commits):

- `feat:` nova funcionalidade
- `fix:` correção de bug
- `docs:` só documentação
- `refactor:` mudança de código sem alterar comportamento
- `test:` adicionar/corrigir testes
- `chore:` tarefas de manutenção (deps, configs)

## 🚫 Antes de commitar

- **Nunca** comite `.venv/`, `__pycache__/`, arquivos de IDE
- **Nunca** comite senhas reais em `config.json` (o padrão `postgres/postgres` é aceitável)
- **Nunca** comite arquivos de trabalho (`DDL_backup.sql`, `update_projeto.py`) — estão no `.gitignore`

## 🧪 Testando antes de abrir PR

```bash
# 1. Banco rodando?
docker ps --filter name=postgres-eventos

# 2. Ollama rodando?
docker ps --filter name=ollama

# 3. Protótipo funciona?
cd Prototipo && source .venv/bin/activate && python main.py
# Teste as opções 1, 2, 3, 4, 5 e 6

# 4. DDL ainda roda do zero?
cd ..
# (executar o comando de DDL do README)
```

## 🐛 Reportando bugs

Abra uma Issue com:
- O que você fez
- O que esperava
- O que aconteceu (incluindo a mensagem de erro **completa**)
- Versões: `python --version`, `docker --version`, `docker exec ollama ollama --version`

## 💡 Sugerindo melhorias

Abra uma Issue com a tag `enhancement` explicando:
- O problema atual
- A solução proposta
- O impacto esperado (afeta a entrega? melhora UX? corrige bug?)
