# extractor

A Ruby CLI tool for extracting basic MP3 metadata to JSON

## Dependencies

Requires that `ffmpeg` is installed and available.

## Usage

`ruby extractor.rb path_to_mp3_file`

## Output

`metadata.json`:

```json
{
    "title": "Never Gonna Give You Up",
    "artist": "Rick Astley",
    "album": "Whenever You Need Somebody",
    "picture": {
        "mime_type": "image/jpeg",
        "data": "base64 encoded blob"
    }
}
```
