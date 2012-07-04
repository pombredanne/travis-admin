source = new EventSource("events/stream")
source.onmessage = (event) -> console.log event.data