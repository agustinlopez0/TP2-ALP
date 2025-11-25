# Intérprete de Lambda Cálculo Simplemente Tipado

[![Haskell](https://img.shields.io/badge/language-Haskell-purple.svg)](https://www.haskell.org/)
[![Stack](https://img.shields.io/badge/build-Stack-blue.svg)](https://docs.haskellstack.org/)
[![License](https://img.shields.io/badge/license-BSD3-green.svg)](LICENSE)

Un intérprete completo e interactivo de **Lambda Cálculo Simplemente Tipado (STLC)** implementado en Haskell, con extensiones para números naturales, listas y expresiones `let`.

## 📋 Características

- ✅ **Evaluador call-by-value** con sustitución correcta
- ✅ **Inferidor de tipos** con verificación estática
- ✅ **Parser** usando Happy con soporte para comentarios anidados
- ✅ **Pretty Printer** para visualización de términos y tipos
- ✅ **Intérprete interactivo** con REPL completo
- ✅ **Extensiones del lenguaje**:
  - Números naturales con recursión primitiva (`R`)
  - Listas de naturales con recursión (`RL`)
  - Expresiones `let` para definiciones locales

## 🚀 Instalación

### Requisitos

- [Stack](https://docs.haskellstack.org/) (herramienta de build para Haskell)
- GHC 8.8.3 (se instala automáticamente con Stack)

### Pasos de instalación

1. Clona el repositorio:
```bash
git clone <url-del-repositorio>
cd TP2-ALP
```

2. Configura Stack (solo la primera vez):
```bash
stack setup
```

3. Compila el proyecto:
```bash
stack build
```

## 💻 Uso

### Ejecutar el intérprete interactivo

```bash
stack exec TP2-exe
```

Esto iniciará el REPL donde puedes escribir expresiones y comandos.

### Cargar archivos de ejemplo

```bash
stack exec TP2-exe -- Ejemplos/Naturales.lam Ejemplos/Listas.lam
```

### Comandos disponibles

Una vez en el intérprete, puedes usar los siguientes comandos:

| Comando | Descripción |
|---------|-------------|
| `:?` o `:help` | Mostrar ayuda |
| `:type <expresión>` | Inferir el tipo de una expresión |
| `:print <expresión>` | Mostrar el AST de una expresión |
| `:browse` | Listar todas las definiciones en scope |
| `:load <archivo>` | Cargar un archivo |
| `:reload` | Recargar el último archivo |
| `:quit` | Salir del intérprete |
| `def <nombre> = <expresión>` | Definir una variable |
| `<expresión>` | Evaluar una expresión |

## 📚 Ejemplos

### Lambda cálculo básico

```haskell
-- Identidad
def I = \x:E. x

-- Constante
def K = \x:E.\y:E.x

-- Combinador S
def S = \x:E->E->E.\y:E->E.\z:E.(x z) (y z)
```

### Números naturales

```haskell
def zero = 0
def one = suc zero
def two = suc one

-- Predecesor usando recursión primitiva
def pred = \r:Nat.R 0 (\n:Nat.\m:Nat.n) r
```

### Listas

```haskell
def mylist = cons two (cons one (cons 0 nil))

-- Suma de una lista
def sumList = RL 0 (\n:Nat. \lv:List Nat. \acc:Nat. suc acc) mylist
```

### Expresiones let

```haskell
let x = 0 in suc x
```

## 🏗️ Estructura del Proyecto

```
TP2-ALP/
├── app/
│   └── Main.hs              # Punto de entrada y REPL interactivo
├── src/
│   ├── Common.hs            # Tipos de datos base (Term, Type, Value)
│   ├── Simplytyped.hs       # Evaluador e inferidor de tipos
│   ├── PrettyPrinter.hs     # Formateo de términos y tipos
│   └── Parse.y              # Gramática del parser (Happy)
├── Ejemplos/
│   ├── Prelude.lam          # Definiciones básicas
│   ├── Naturales.lam       # Ejemplos con números naturales
│   ├── Listas.lam           # Ejemplos con listas
│   ├── Ej7.lam              # Ejercicio 7
│   └── Ack.lam              # Función de Ackermann
├── stack.yaml               # Configuración de Stack
└── package.yaml             # Configuración del paquete
```

## 🔧 Componentes Principales

### Evaluador (`Simplytyped.hs`)

Implementa evaluación call-by-value con:
- Sustitución correcta usando índices de De Bruijn
- Evaluación de funciones, aplicaciones y expresiones `let`
- Recursión primitiva para naturales (`R`)
- Recursión para listas (`RL`)

### Inferidor de Tipos (`Simplytyped.hs`)

Sistema de tipos con:
- Inferencia de tipos para todos los constructores
- Verificación de tipos de funciones
- Mensajes de error descriptivos
- Soporte para tipos base (`E`, `Nat`, `List Nat`) y funciones

### Parser (`Parse.y`)

Gramática BNF implementada con Happy:
- Lexer con soporte para comentarios anidados `{- -}`
- Precedencia correcta de operadores
- Parsing de tipos y términos

### Pretty Printer (`PrettyPrinter.hs`)

Formateo inteligente de:
- Términos con nombres de variables frescos
- Tipos con paréntesis según necesidad
- Expresiones complejas con indentación

## 📖 Sintaxis del Lenguaje

### Tipos

```
Type ::= E                    -- Tipo vacío
      | Nat                   -- Números naturales
      | List Nat              -- Listas de naturales
      | Type -> Type          -- Funciones
      | (Type)                -- Paréntesis
```

### Términos

```
Term ::= VAR                  -- Variable
      | \VAR:Type.Term        -- Abstracción lambda
      | Term Term             -- Aplicación
      | let VAR = Term in Term -- Expresión let
      | 0                     -- Cero
      | suc Term              -- Sucesor
      | R Term Term Term      -- Recursión primitiva
      | nil                   -- Lista vacía
      | cons Term Term        -- Constructor de lista
      | RL Term Term Term     -- Recursión sobre listas
      | (Term)                -- Paréntesis
```

## 🧪 Testing

Ejecuta los tests incluidos:

```bash
cd Ejemplos
./run_tests.sh
```

## 📝 Licencia

Este proyecto está bajo la licencia BSD3. Ver el archivo [LICENSE](LICENSE) para más detalles.

## 👥 Autor

Trabajo Práctico 2 - Análisis de Lenguajes de Programación (ALP)

## 🙏 Agradecimientos

- Implementado usando [Stack](https://docs.haskellstack.org/)
- Parser generado con [Happy](https://www.haskell.org/happy/)
- Pretty printing con [pretty](https://hackage.haskell.org/package/pretty)

---

⭐ Si este proyecto te resultó útil, considera darle una estrella en GitHub.

