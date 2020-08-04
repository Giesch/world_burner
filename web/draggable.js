window.setupDraggable = function setupDraggable(sendEvent) {
  const BEACON_ATTRIBUTE = "data-beacon";
  const MINIMUM_DRAG_DISTANCE_PX = 10;

  // browser events
  const POINTER_DOWN = "pointerdown";
  const POINTER_MOVE = "pointermove";
  const POINTER_UP = "pointerup";

  // elm events
  const MOVE = "move";
  const STOP = "stop";
  const START = "start";
  const HOVER = "hover";

  document.addEventListener(POINTER_DOWN, awaitDragStart);
  document.addEventListener(POINTER_MOVE, hover);

  function awaitDragStart(startEvent) {
    let startBeaconId = null;
    let cursorOnDraggable = null;
    const startBeaconElem = startEvent.target.closest(`[${BEACON_ATTRIBUTE}]`);
    if (startBeaconElem) {
      startBeaconId = startBeaconElem.getAttribute(BEACON_ATTRIBUTE);
      const { left, top } = startBeaconElem.getBoundingClientRect();
      cursorOnDraggable = {
        x: startEvent.clientX - left,
        y: startEvent.clientY - top,
      };
    }

    changeMoveListener(hover, maybeDragMove);
    document.addEventListener(POINTER_UP, stopAwaitingDrag);

    function stopAwaitingDrag() {
      changeMoveListener(maybeDragMove, hover);
      document.removeEventListener(POINTER_UP, stopAwaitingDrag);
    }

    function maybeDragMove(moveEvent) {
      const dragDistance = distance(coords(startEvent), coords(moveEvent));
      if (dragDistance >= MINIMUM_DRAG_DISTANCE_PX) {
        sendStartEvent(startEvent, startBeaconId, cursorOnDraggable);
        sendDragEvent(MOVE, moveEvent);

        changeMoveListener(maybeDragMove, dragMove);
        document.removeEventListener(POINTER_UP, stopAwaitingDrag);
        document.addEventListener(POINTER_UP, dragEnd);
      }
    }
  }

  function dragEnd(event) {
    sendDragEvent(STOP, event);
    changeMoveListener(dragMove, hover);
    document.removeEventListener(POINTER_UP, dragEnd);
  }

  function dragMove(event) {
    sendDragEvent(MOVE, event);
  }

  function hover(moveEvent) {
    sendDragEvent(HOVER, moveEvent);
  }

  function sendStartEvent(event, startBeaconId, cursorOnDraggable) {
    sendEvent({
      type: START,
      cursor: coords(event),
      beacons: beaconPositions(),
      startBeaconId,
      cursorOnDraggable,
    });
  }

  function sendDragEvent(type, event) {
    sendEvent({
      type: type,
      cursor: coords(event),
      beacons: beaconPositions(),
    });
  }

  function changeMoveListener(from, to) {
    document.removeEventListener(POINTER_MOVE, from);
    document.addEventListener(POINTER_MOVE, to);
  }

  function beaconPositions() {
    const beaconElements = document.querySelectorAll(`[${BEACON_ATTRIBUTE}]`);
    return Array.from(beaconElements).map(beaconData);
  }

  function beaconData(elem) {
    const boundingRect = elem.getBoundingClientRect();
    const beaconId = elem.getAttribute(BEACON_ATTRIBUTE);
    return {
      id: tryParse(beaconId),
      x: boundingRect.x,
      y: boundingRect.y,
      width: boundingRect.width,
      height: boundingRect.height,
    };
  }

  function tryParse(str) {
    try {
      return JSON.parse(str);
    } catch (e) {
      return str;
    }
  }

  function coords(event) {
    return { x: event.clientX, y: event.clientY };
  }

  function distance(pos1, pos2) {
    const dx = pos1.x - pos2.x;
    const dy = pos1.y - pos2.y;
    return Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));
  }
};
