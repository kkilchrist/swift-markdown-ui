# MarkdownUI (Obsidian Extensions Fork)

[![CI](https://github.com/gonzalezreal/MarkdownUI/workflows/CI/badge.svg)](https://github.com/gonzalezreal/MarkdownUI/actions?query=workflow%3ACI)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fgonzalezreal%2Fswift-markdown-ui%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/gonzalezreal/swift-markdown-ui)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fgonzalezreal%2Fswift-markdown-ui%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/gonzalezreal/swift-markdown-ui)

This is a fork of [gonzalezreal/swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui) that adds support for [Obsidian](https://obsidian.md/)-style markdown extensions.

## Why This Fork?

The upstream MarkdownUI library is in [maintenance mode](https://github.com/gonzalezreal/swift-markdown-ui/discussions/437). Rather than wait for new features or maintain complex preprocessing workarounds, this fork adds minimal, focused extensions to support Obsidian-flavored markdown:

- **Highlight syntax** (`==highlighted text==`)
- **Callout blocks** (`> [!note]`, `> [!warning]`, etc.)

These extensions integrate cleanly with MarkdownUI's existing theming system and require no preprocessing of your markdown content.

## Installation

```swift
// In your Package.swift
.package(url: "https://github.com/kkilchrist/swift-markdown-ui.git", branch: "main")
```

Or in Xcode: **File → Add Packages** → `https://github.com/kkilchrist/swift-markdown-ui.git`

## Obsidian Extensions

### Highlight Syntax

Highlight text using `==text==`:

```swift
Markdown("This has ==highlighted text== in a sentence.")
```

Or with the DSL:

```swift
Markdown {
  Paragraph {
    "This is "
    Highlight("important")
    " information."
  }
}
```

Customize the style:

```swift
Markdown(content)
  .markdownTextStyle(\.highlight) {
    BackgroundColor(.pink.opacity(0.3))
  }
```

### Callouts

Callouts are styled blockquotes with an icon, color, and optional title:

```swift
Markdown {
  """
  > [!note]
  > This is a note callout.

  > [!warning] Be Careful
  > This is a warning with a custom title.

  > [!tip]
  > Tips are displayed in cyan.
  """
}
```

Or with the DSL:

```swift
Markdown {
  Callout(.warning, title: "Important") {
    Paragraph {
      "This action cannot be undone."
    }
  }
}
```

#### Supported Callout Types

| Type | Color |
|------|-------|
| `note`, `info`, `todo` | blue |
| `abstract`, `summary`, `tip`, `hint`, `important` | cyan |
| `success`, `check`, `done` | green |
| `question`, `help`, `faq`, `warning`, `caution`, `attention` | orange |
| `failure`, `fail`, `missing`, `danger`, `error`, `bug` | red |
| `example` | purple |
| `quote`, `cite` | gray |

Customize the callout style:

```swift
Markdown(content)
  .markdownBlockStyle(\.callout) { configuration in
    HStack(alignment: .top) {
      Image(systemName: configuration.calloutType?.iconName ?? "info.circle")
        .foregroundColor(configuration.calloutType?.color ?? .gray)
      VStack(alignment: .leading) {
        if let title = configuration.title ?? configuration.calloutType?.rawValue.capitalized {
          Text(title).fontWeight(.semibold)
        }
        configuration.label
      }
    }
    .padding()
    .background(configuration.calloutType?.color.opacity(0.1) ?? .gray.opacity(0.1))
  }
```

## Other Useful Features

MarkdownUI includes a built-in soft break mode that's useful for Obsidian-style line handling:

```swift
// Treat soft breaks (single newlines) as line breaks instead of spaces
Markdown(content)
  .markdownSoftBreakMode(.lineBreak)
```

This eliminates the need for preprocessing markdown to add trailing spaces for line breaks.

---

## Original MarkdownUI Documentation

The sections below are from the original MarkdownUI library.

### Overview

MarkdownUI is a powerful library for displaying and customizing Markdown text in SwiftUI. It is compatible with the [GitHub Flavored Markdown Spec](https://github.github.com/gfm/) and can display images, headings, lists (including task lists), blockquotes, code blocks, tables, and thematic breaks, besides styled text and links.

### Minimum Requirements

- macOS 12.0+
- iOS 15.0+
- tvOS 15.0+
- watchOS 8.0+

Tables and multi-image paragraphs require macOS 13.0+, iOS 16.0+, tvOS 16.0+, or watchOS 9.0+.

### Creating a Markdown View

```swift
Markdown("**Hello**, *world*!")
```

Or with the content builder:

```swift
Markdown {
  Heading(.level2) {
    "Getting Started"
  }
  Paragraph {
    Strong("MarkdownUI")
    " is a native Markdown renderer for SwiftUI."
  }
}
```

### Theming

Apply built-in themes:

```swift
Markdown(content)
  .markdownTheme(.gitHub)
```

Override specific styles:

```swift
Markdown(content)
  .markdownTextStyle(\.code) {
    FontFamilyVariant(.monospaced)
    ForegroundColor(.purple)
  }
  .markdownBlockStyle(\.blockquote) { configuration in
    configuration.label
      .padding()
      .background(Color.gray.opacity(0.1))
  }
```

Create custom themes:

```swift
extension Theme {
  static let myTheme = Theme()
    .code {
      FontFamilyVariant(.monospaced)
      FontSize(.em(0.85))
    }
    .paragraph { config in
      config.label
        .relativeLineSpacing(.em(0.25))
    }
}
```

### Documentation

Full documentation for the base library is available at [Swift Package Index](https://swiftpackageindex.com/gonzalezreal/swift-markdown-ui/main/documentation/markdownui).

### Upstream Repository

This fork is based on [gonzalezreal/swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui). For issues unrelated to the Obsidian extensions, please refer to the upstream repository.
