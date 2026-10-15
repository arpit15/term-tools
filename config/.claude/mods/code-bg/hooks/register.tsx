import type { Register } from 'claude-code'

// Change this to taste: a hex color or a theme key.
const CODE_BACKGROUND = '#4b4540'


const FENCE = /^```([^\n`]*)\n([\s\S]*?)\n```[ \t]*$/gm

type Part =
  | { kind: 'prose'; text: string }
  | { kind: 'code'; language: string; source: string }

function split(text: string): Part[] {
  const parts: Part[] = []
  let last = 0

  for (const m of text.matchAll(FENCE)) {
    const at = m.index ?? 0
    if (at > last) parts.push({ kind: 'prose', text: text.slice(last, at) })
    parts.push({ kind: 'code', language: (m[1] ?? '').trim(), source: m[2] ?? '' })
    last = at + m[0].length
  }

  if (last < text.length) parts.push({ kind: 'prose', text: text.slice(last) })

  return parts
}

export const register: Register = on => {
  on('ui.render', { component: 'AssistantMessage' }, ($, e, next) => {
    const { text, isSummary } = e.props

    if (isSummary || !text.includes('```')) {
      return next(e)
    }

    const parts = split(text)

    if (!parts.some(p => p.kind === 'code')) {
      return next(e)
    }

    const { Box, Code, Markdown } = $.ui.resolve(e)

    return (
      <Box flexDirection="column">
        {parts.map((p, i) =>
          p.kind === 'code' ? (
            <Box key={`c${i}`} backgroundColor={CODE_BACKGROUND} paddingX={1}>
              <Code source={p.source} language={p.language || undefined} />
            </Box>
          ) : (
            <Markdown key={`m${i}`} text={p.text.trim()} />
          ),
        )}
      </Box>
    )
  })
}
