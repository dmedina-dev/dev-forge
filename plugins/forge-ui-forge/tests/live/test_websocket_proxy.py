"""WebSocket proxy — bidirectional pump between client and upstream WS."""

from __future__ import annotations

import asyncio
import os

import aiohttp
import pytest


async def test_websocket_text_frame_round_trips(live_proxy):
    """Client sends text → upstream echoes → client receives same text."""
    client, _base, _recorder = live_proxy

    async with client.ws_connect("/ws") as ws:
        await ws.send_str("hello")
        msg = await asyncio.wait_for(ws.receive(), timeout=2.0)
        assert msg.type == aiohttp.WSMsgType.TEXT
        assert msg.data == "hello"
        await ws.close()


async def test_websocket_binary_frame_round_trips(live_proxy):
    client, _base, _recorder = live_proxy
    payload = os.urandom(1024)

    async with client.ws_connect("/ws") as ws:
        await ws.send_bytes(payload)
        msg = await asyncio.wait_for(ws.receive(), timeout=2.0)
        assert msg.type == aiohttp.WSMsgType.BINARY
        assert msg.data == payload
        await ws.close()


async def test_client_close_propagates_to_upstream(live_proxy):
    """Closing the client WS should close the upstream WS within 1s."""
    client, _base, recorder = live_proxy

    ws = await client.ws_connect("/ws")
    # Send one frame so the upstream definitely registers the connection
    await ws.send_str("ping")
    await asyncio.wait_for(ws.receive(), timeout=2.0)
    assert len(recorder.active_ws) == 1

    await ws.close()

    deadline = asyncio.get_event_loop().time() + 1.5
    while asyncio.get_event_loop().time() < deadline:
        if len(recorder.active_ws) == 0:
            break
        await asyncio.sleep(0.05)
    assert len(recorder.active_ws) == 0, (
        f"upstream WS did not close: {len(recorder.active_ws)} still active"
    )


async def test_concurrent_websocket_connections_are_independent(live_proxy):
    """Two simultaneous WS connections do not interfere with each other."""
    client, _base, _recorder = live_proxy

    async with client.ws_connect("/ws") as ws_a, client.ws_connect("/ws") as ws_b:
        await ws_a.send_str("alpha")
        await ws_b.send_str("beta")

        msg_a = await asyncio.wait_for(ws_a.receive(), timeout=2.0)
        msg_b = await asyncio.wait_for(ws_b.receive(), timeout=2.0)

        assert msg_a.data == "alpha"
        assert msg_b.data == "beta"
