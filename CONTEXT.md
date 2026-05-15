# CodeIsland

CodeIsland is a macOS notch-resident status surface for AI coding agents. It balances glanceable agent state in the top bar with deeper interaction surfaces when the user chooses to expand.

## Language

**Island**:
The notch-aligned top-bar surface that remains visible while CodeIsland is active.
_Avoid_: Notch panel, top pill, bar

**Collapsed Island**:
The compact Island state that shows glanceable agent status without the below-notch panel.
_Avoid_: Small panel, minimized panel

**Collapsed Island Width**:
The resting width of the Collapsed Island, matched to the physical notch baseline when available and user-configurable on notchless displays.
_Avoid_: Automatic content width, arbitrary user width

**Hover Preview Width**:
The temporary wider width of the Collapsed Island while the pointer is hovering, showing more top-bar status content without opening the expanded panel.
_Avoid_: Expand, full expand, session list

**Hover Preview Width Limit**:
The user-configured maximum width the Collapsed Island may reach during hover preview.
_Avoid_: Expanded panel width, session list width

**Hover-to-Expand**:
The delayed transition from hover preview into the Expanded Panel after the pointer remains on the Island long enough.
_Avoid_: Immediate hover preview

**Expanded Panel**:
The below-notch interactive surface that shows session lists, approvals, questions, or completion cards.
_Avoid_: Hover preview, long island

## Relationships

- A **Collapsed Island** uses a **Collapsed Island Width** matched to the physical notch baseline when available.
- On notchless displays, **Collapsed Island Width** is manually configurable.
- On notched displays, **Collapsed Island Width** controls are hidden or disabled because the width is defined by the physical notch baseline.
- **Collapsed Island Width** settings for notchless displays are global, not per-display.
- A **Collapsed Island** may temporarily use a **Hover Preview Width** up to the **Hover Preview Width Limit**.
- **Hover Preview Width Limit** is configurable on both notched and notchless displays.
- **Hover Preview Width Limit** must be at least the current **Collapsed Island Width**.
- **Hover Preview Width Limit** is global, not per-display.
- A **Hover Preview Width** does not open the **Expanded Panel**.
- A **Hover Preview Width** may reveal more top-bar status content, but it does not show the session list.
- Top-bar content revealed by **Hover Preview Width** prioritizes current tool/status, then session title, then working directory.
- **Hover-to-Expand** opens the **Expanded Panel** when the pointer remains on the hover preview for 0.8 seconds.
- An **Expanded Panel** is a distinct surface from the **Collapsed Island**.

## Example Dialogue

> **Dev:** "When the user first hovers over the Island, should we show the session list?"
> **Domain expert:** "No. Hover first widens the Collapsed Island up to the preview limit; only Hover-to-Expand opens the Expanded Panel after a longer dwell."

## Flagged Ambiguities

- "拉长" could mean opening the **Expanded Panel** or widening the **Collapsed Island**. Resolved: initial hover means widening the **Collapsed Island**; a longer hover may trigger **Hover-to-Expand**.
- "自动调整缩小长度" could mean content-based auto-sizing, a user-configured resting width, or matching the physical notch baseline. Resolved: it means matching the physical notch baseline when available, with manual resting width on notchless displays.
