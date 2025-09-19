import ws from "k6/ws";
import { check, sleep } from "k6";
import { Trend } from "k6/metrics";

// ---- Config ----
export const options = {
  vus: __ENV.VUS ? parseInt(__ENV.VUS) : 50, // jumlah virtual users
  duration: __ENV.DURATION || "30s", // lama test
};

const dialTrend = new Trend("ws_dial_time_ms");

const BASE_URL = __ENV.URL || "ws://localhost:4000/socket/websocket";
const VSN = __ENV.VSN || "2.0.0";
const MESSAGE_INTERVAL_MS = __ENV.MSG_INTERVAL_MS
  ? parseInt(__ENV.MSG_INTERVAL_MS)
  : 2000;
// ----------------

export default function () {
  const userId = __VU; // assign user_id berdasarkan VU number
  const url = `${BASE_URL}?user_id=${userId}&vsn=${VSN}`;

  const res = ws.connect(url, {}, function (socket) {
    const start = Date.now();

    socket.on("open", () => {
      dialTrend.add(Date.now() - start);

      console.log(`VU ${userId} connected`);
      // Join order channel contoh: "order:123"
      const joinMsg = [null, null, "order:123", "phx_join", {}];
      socket.send(JSON.stringify(joinMsg));
    });

    socket.on("message", (msg) => {
      console.log(`VU ${userId} got message: ${msg}`);
    });

    // kirim pesan tiap interval
    socket.setInterval(() => {
      const pushMsg = [
        null,
        null,
        "order:123",
        "ping",
        { user: userId, ts: Date.now() },
      ];
      socket.send(JSON.stringify(pushMsg));
    }, MESSAGE_INTERVAL_MS);

    socket.on("close", () => console.log(`VU ${userId} closed`));
    socket.on("error", (e) => console.error(`VU ${userId} error: ${e}`));

    // biarkan koneksi terbuka 1 menit
    socket.setTimeout(() => {
      socket.close();
    }, 60000);
  });

  check(res, { "status is 101": (r) => r && r.status === 101 });
  sleep(1);
}
