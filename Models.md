# Models (Asset)

## Agrupamentos / Instituiçoes

- Nome
- Morada
- Ano

## Escolas / Faculdades

- [FK] Agrupamento
- Nome
- Morada

### Níveis [ENUM] (9o ano, liceciatura, Mestrado)

## Cursos / ciclos

- [FK] Escolas
- Nome
- [FK] Nivel

## Cadeiras / Disciplinas

- [FK] Curso
- Nome
- Ano

(Turmas)

## Professores

- [FK] Cadeira
- Nome
- Data Nascimento
- Email
- Contato

## Tutores

- Nome
- Morada
- Data Nascimento
- CC/Passsaporte
- Contato
- Email

## Alunos

- [] [FK] Tutores
- Nome
- Morada
- Data Nascimento