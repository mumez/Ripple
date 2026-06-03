export class Ripple {
  static CONNECTING = 0;
  static OPEN = 1;
  static CLOSING = 2;
  static CLOSED = 3;

  constructor(url, options = {}) {
    this.state = Ripple.CONNECTING;
    this.subscriptions = {};
    this.pendingRequests = {};
    this.headers = options.headers || {};
    this.onOpenHandler  = options.onOpen  || (() => console.log("--open--"));
    this.onCloseHandler = options.onClose || (() => console.log("--close--"));
    this.onErrorHandler = options.onError || ((json) => console.error(json));
    this.setupWebsocket(url, options);
  }

  setupWebsocket(url, options) {
    const pingInterval = options.ping_interval || 10000;

    let pingTimerID;
    this.wsock = new WebSocket(url, ["ripple-st.0"]);
    this.wsock.onopen = () => {
      const sendPing = () => {
        this.wsock.send(JSON.stringify({ type: "ping" }));
      };
      sendPing();
      pingTimerID = setInterval(sendPing, pingInterval);
      this.state = Ripple.OPEN;
      this.onOpenHandler(this);
    };

    this.wsock.onclose = () => {
      this.state = Ripple.CLOSED;
      if (pingTimerID) clearInterval(pingTimerID);
      this.onCloseHandler(this);
    };

    this.wsock.onmessage = (e) => {
      const json = JSON.parse(e.data);
      const { type } = json;

      if (type === "pong") {
        return;
      }

      if (type === "reply") {
        const callback = this.pendingRequests[json.correlationId];
        if (callback) {
          delete this.pendingRequests[json.correlationId];
          callback(json.body, null);
        }
        return;
      }

      if (type === "err" && json.correlationId) {
        const callback = this.pendingRequests[json.correlationId];
        if (callback) {
          delete this.pendingRequests[json.correlationId];
          callback(null, json);
        }
        return;
      }

      const handlers = this.subscriptions[json.address];
      if (handlers) {
        handlers.forEach((handler) => {
          if (type === "err") {
            handler(null, json);
          } else {
            handler(json.body, null);
          }
        });
      } else {
        if (type === "err") {
          this.handleMessageError(json);
        } else {
          console.warn("No handler found for message: ", json);
        }
      }
    };
  }

  handleMessageError(json) {
    this.onErrorHandler(json);
  }

  // callbacks
  onClose(onCloseHandler) {
    this.onCloseHandler = onCloseHandler;
  }

  onOpen(onOpenHandler) {
    this.onOpenHandler = onOpenHandler;
  }

  onError(onErrorHandler) {
    this.onErrorHandler = onErrorHandler;
  }

  // actions

  // Send a request and expect a reply via callback(body, error).
  // Server must handle type:'request' and reply with type:'reply'+correlationId.
  request(address, message, callback) {
    if (this.state != Ripple.OPEN) {
      throw new Error("INVALID_STATE_ERR");
    }

    const correlationId = this.makeUUID();
    const envelope = {
      type: "request",
      address: address,
      headers: this.headers,
      body: message,
      correlationId: correlationId,
    };

    if (callback) {
      this.pendingRequests[correlationId] = callback;
    }

    this.wsock.send(JSON.stringify(envelope));
  }

  // One-way send with no reply expected.
  send(address, message) {
    if (this.state != Ripple.OPEN) {
      throw new Error("INVALID_STATE_ERR");
    }

    this.wsock.send(
      JSON.stringify({
        type: "send",
        address: address,
        headers: this.headers,
        body: message,
      }),
    );
  }

  publish(address, message) {
    if (this.state != Ripple.OPEN) {
      throw new Error("INVALID_STATE_ERR");
    }

    this.wsock.send(
      JSON.stringify({
        type: "publish",
        address: address,
        headers: this.headers,
        body: message,
      }),
    );
  }

  registerHandler(address, callback) {
    if (this.state != Ripple.OPEN) {
      throw new Error("INVALID_STATE_ERR");
    }

    if (!this.subscriptions[address]) {
      this.subscriptions[address] = [];
      this.wsock.send(
        JSON.stringify({
          type: "register",
          address: address,
          headers: this.headers,
        }),
      );
    }

    this.subscriptions[address].push(callback);
  }

  unregisterHandler(address, callback) {
    if (this.state != Ripple.OPEN) {
      throw new Error("INVALID_STATE_ERR");
    }

    const handlers = this.subscriptions[address];

    if (handlers) {
      const idx = handlers.indexOf(callback);
      if (idx != -1) {
        handlers.splice(idx, 1);
        if (handlers.length === 0) {
          this.wsock.send(
            JSON.stringify({
              type: "unregister",
              address: address,
              headers: this.headers,
            }),
          );

          delete this.subscriptions[address];
        }
      }
    }
  }

  close() {
    this.state = Ripple.CLOSING;
    this.wsock.close();
  }

  // private
  makeUUID() {
    return crypto.randomUUID();
  }
}
