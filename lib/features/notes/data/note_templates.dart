/// Predefined note templates matching LifeOS web note-templates.ts
class NoteTemplate {
  final String id;
  final String name;
  final String icon;
  final String title;
  final String content;

  const NoteTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.title,
    required this.content,
  });
}

const List<NoteTemplate> noteTemplates = [
  NoteTemplate(
    id: 'blank',
    name: 'Blank',
    icon: 'note_add',
    title: '',
    content: '',
  ),
  NoteTemplate(
    id: 'daily',
    name: 'Daily Note',
    icon: 'today',
    title: 'Daily Note',
    content: '''# Daily Note

## Tasks
- [ ] 

## Notes


## Reflections
''',
  ),
  NoteTemplate(
    id: 'meeting',
    name: 'Meeting Notes',
    icon: 'groups',
    title: 'Meeting Notes',
    content: '''# Meeting Notes

## Attendees
- 

## Agenda
1. 

## Discussion


## Action Items
- [ ] 
''',
  ),
  NoteTemplate(
    id: 'project',
    name: 'Project Plan',
    icon: 'work',
    title: 'Project Plan',
    content: '''# Project Plan

## Overview


## Goals
- 

## Milestones
1. 

## Tasks
- [ ] 

## Notes
''',
  ),
  NoteTemplate(
    id: 'idea',
    name: 'Idea',
    icon: 'lightbulb',
    title: 'New Idea',
    content: '''# New Idea

## Concept


## Why?


## How?


## Next Steps
- [ ] 
''',
  ),
];
