# 🎵 Prompt Session Feature — Development Specification

## Overview

Build a **Prompt Session** feature that allows users to create named sessions, attach songs to those sessions, and browse through song content in a focused, read-only viewer. This document defines all UI behavior, layout rules, interactions, and component expectations.

---

## 1. Session Creation

### Entry Point
- From the main sessions list screen, the user sees a list of all previously created sessions.
- A clearly visible **"Create Session"** button (or CTA) is present on this screen.

### Creation Flow
- Clicking "Create Session" opens a **modal or inline form** prompting the user to enter:
  - **Session Name** (required, text input)
  - Optionally: a short description or tags (if applicable to the broader app design)
- On confirmation/submit, the session is saved and the user is **immediately navigated into the newly created session**.

### Session List View
- All created sessions are listed as cards or rows.
- Each entry shows the **session name** and relevant metadata (e.g., date created, number of songs).
- Clicking any session navigates the user into that session's detail view.

---

## 2. Session Detail View — Layout & Structure

### Header Bar
- Fixed at the top of the screen.
- **Left side:**
  - A **"← Back"** (go back) button/link — returns to the session list.
  - Immediately next to it (right of the back button): the **Session Name** displayed as a heading/title.
- **Right side:** No extra controls. Keep the header minimal and uncluttered.
- **Important:** No song editing controls, settings, or unrelated options are shown anywhere in the session view. The session detail page is focused and clean.

---

## 3. Left Sidebar — Song Panel

### Purpose
The sidebar lists all songs that have been added to the current session. It serves as a navigation panel for jumping between songs.

### Expand / Collapse Behavior

#### Expanded State
- The sidebar occupies **60% of the total screen width**.
- Displays a vertical list of all added songs, where **each song is rendered as a distinct rectangular card** (not a plain list row). Cards should have visible borders, background fill, padding, and subtle shadow to make each song feel like a tactile, selectable tile.
- Each song card is clickable — clicking a song loads it into the main content area.
- **Card visual states:**
  - **Default (unselected):** Card has a clear, prominent styled appearance — elevated background, readable title, song metadata. High visual weight so the list feels substantial, not flat.
  - **Selected / Active:** The currently selected song's card is **highlighted more prominently** — use a strong accent color fill, bold border, or elevated shadow to make it unmistakably distinct from the others at a glance.
- A **collapse toggle button** (e.g., `‹` chevron or panel-close icon) is visible at the top or edge of the sidebar to allow collapsing.

#### Collapsed State
- The sidebar is hidden/minimized — it takes up minimal horizontal space (e.g., a thin rail, ~40–48px wide).
- **Centered vertically on the left edge**, a single **expand icon** (e.g., `›` chevron or hamburger/panel icon) is visible.
- Clicking this icon expands the sidebar back to its 60% width.
- The transition between expanded and collapsed should be **animated smoothly** (CSS transition or equivalent).

#### Behavior Notes
- The sidebar state (expanded/collapsed) should persist during the session (does not reset on song navigation).
- On mobile or small screens, the sidebar should behave as a **drawer overlay** rather than a push layout.

### Song Order — Drag to Reorder

Users can manually reorder songs in the session by dragging cards up or down within the sidebar list.

#### Interaction Design
- Each song card has a **drag handle** — either a dedicated grip icon (⠿ or `≡` dots/lines) on the left side of the card, or the entire card surface acts as the drag target (tap-and-hold to initiate drag on touch devices).
- On **desktop**: click and hold on the card (or drag handle) then drag vertically to reposition.
- On **touch/mobile**: long-press (tap and hold ~150–200ms) on the card to activate drag mode, then drag up or down.

#### Drag Behavior
- When a card is being dragged:
  - It visually **lifts** — increase shadow/elevation and slightly reduce opacity (e.g., 0.85) to indicate it is in motion and detached from the list.
  - A **placeholder gap** (ghost outline or empty slot) appears in the list at the position where the card will be dropped if released, giving the user clear positional feedback.
  - Other cards **animate smoothly** to shift up or down as the dragged card passes over them.
- On **drop/release**:
  - The card snaps into its new position with a short settle animation.
  - The updated order is **immediately persisted** to the session data (no separate save step required).
  - The `Previous` / `Next` navigation buttons in the main content area reflect the new order instantly.

#### Visual States During Drag

| State | Visual Treatment |
|---|---|
| Idle card | Prominent rectangle card, default background, subtle shadow |
| Active / selected card | Strong accent color, bold border, elevated shadow |
| Card being dragged | Lifted shadow, slight opacity reduction, follows cursor/finger |
| Drop placeholder | Ghost outline or dimmed empty slot showing target position |
| Other cards (reordering) | Smooth up/down shift animation as dragged card passes |

#### Rules & Edge Cases
- Drag reorder is **only available in the expanded sidebar state**. In collapsed mode there is no drag interaction.
- If the session has only one song, drag handles are present but non-functional (or hidden).
- Drag reorder does **not** change which song is currently selected/displayed in the main view — it only changes the list order.
- The new order is reflected immediately in the Prev/Next navigation sequence.

---

## 4. Main Content Area — Song Viewer

### Purpose
Displays the content of the currently selected song in **read-only mode**. Users can read/view song details but cannot edit them here.

### Top Navigation Bar (Previous / Next)
- Positioned at the **top of the main content area**, below the global header.
- Contains two buttons, placed **left and right**:
  - **`← Previous`** button (left-aligned): navigates to the previous song in the session's song list.
  - **`→ Next`** button (right-aligned): navigates to the next song in the session's song list.
- These buttons allow **quick sequential browsing** through all songs in the session.
- The `Previous` button is **disabled** on the first song; the `Next` button is **disabled** on the last song.
- Optionally, show a **song counter** in the center (e.g., "Song 3 of 12") for orientation.

### Song Display
- The full content/details of the selected song are rendered below the prev/next navigation.
- **Read-only**: All fields are displayed as static text. No edit inputs, save buttons, or modification controls are shown.
- If no song is selected yet (empty session), show an **empty state** prompt encouraging the user to add songs.

---

## 5. Add Songs Functionality

### "Add Songs" Button
- Visible within the session detail view — recommended placement: **top of the sidebar (expanded state)** or as a floating/sticky button near the bottom of the sidebar.
- The button is always accessible regardless of how many songs are already in the session.

### Add Songs Modal / Drawer
- Clicking "Add Songs" opens a **modal or full-screen overlay**.
- This view displays **all songs available in the system** (the user's song library).
- **Search and/or filter** functionality should be available to help users find songs quickly.
- Each song entry has a **checkbox or multi-select toggle** for selection.
- Users can **select multiple songs** at once before confirming.
- Already-added songs (those already in the current session) should be visually indicated (e.g., greyed out, checkmark icon, or "Added" badge) and should not be selectable again.

### Confirmation
- A prominent **"Add Selected Songs"** or **"Add [N] Songs"** button (where N = number currently selected) is displayed at the bottom of the modal.
- Clicking this button:
  1. Adds all selected songs to the current session.
  2. Closes the modal.
  3. The newly added songs **immediately appear in the left sidebar song list**.
- If no songs are selected, the confirm button is disabled or shows "Add Songs" in a neutral state.

### Post-Add Behavior
- After adding, the sidebar automatically reflects the updated song list.
- The first newly added song may optionally be auto-selected and displayed in the main view.

---

## 6. State & Data Rules

| Rule | Detail |
|---|---|
| Read-only session view | No song field is editable from within the session |
| Song order | Songs appear in the order added by default; user can manually reorder by dragging cards |
| Order persistence | Drag-reordered sequence saves immediately — no extra save step needed |
| Prev/Next reflects order | Navigation buttons always follow the current drag-defined order |
| Empty session | Show empty state in both sidebar and main area |
| Duplicate prevention | A song already in the session cannot be added again |
| Navigation wrapping | Prev/Next does NOT wrap around (first/last buttons are disabled at boundaries) |
| Drag availability | Drag-to-reorder only active in expanded sidebar; unavailable in collapsed state |
| Selection unaffected by drag | Reordering does not change the currently displayed song in the main viewer |

---

## 7. Component Summary

| Component | Description |
|---|---|
| `SessionListPage` | Lists all sessions; entry point for creation |
| `CreateSessionModal` | Form for naming and creating a new session |
| `SessionDetailPage` | Root layout: header + sidebar + main area |
| `SessionHeader` | Back button + session name |
| `SongSidebar` | Expandable/collapsible panel with draggable song card list |
| `SidebarExpandToggle` | Icon shown in collapsed state to re-open sidebar |
| `SongCard` | Rectangle card for each song — default, active/selected, and drag-lifted visual states |
| `DragHandle` | Grip icon (⠿) on each card to initiate drag-to-reorder |
| `DragPlaceholder` | Ghost/outline slot shown in the list during drag, indicating drop target position |
| `SongNavBar` | Previous / Next buttons + optional song counter |
| `SongViewer` | Read-only display of selected song's content |
| `AddSongsModal` | Song library browser with multi-select + confirm |

---

## 8. UX & Accessibility Notes

- All interactive elements (buttons, toggles) must have clear focus states and ARIA labels.
- The sidebar transition should respect `prefers-reduced-motion` — disable card lift animations and smooth-shift transitions when this preference is set.
- Drag-to-reorder should support **keyboard accessibility** as a fallback: focused song card can be moved up/down using `Ctrl + Arrow Up / Down` or equivalent.
- Use `aria-grabbed`, `aria-dropeffect`, and `role="listitem"` appropriately on draggable song cards.
- The "Back" button should use browser history or router navigation (not a full page reload).
- Song content in the viewer should be scrollable independently of the sidebar.
- The Add Songs modal should be closable via an `✕` button, the `Escape` key, and clicking outside the modal.

---

## 9. Visual / Design Guidance

- Use a **clean, minimal aesthetic** — the session view is a focused workspace, not a dashboard.
- The sidebar in expanded state (60% width) is intentionally large to surface song navigation prominently.
- The collapsed state's expand icon should be **vertically centered on the left edge** and visually unobtrusive but easy to click.
- Previous/Next buttons should feel **quick and tactile** — use clear directional arrows and ensure they are large enough for easy interaction.
- Avoid cluttering the session view with unrelated actions. Every control visible on this screen should directly relate to navigating or managing songs within the session.
