"""AsyncArcKit — minimal async client.

For v0.1 the async surface is a thin wrapper that runs sync client calls in a
thread pool. A native AsyncWeb3 implementation can land in v0.2 once the sync
surface is feedback-validated.
"""

from __future__ import annotations

import asyncio
from typing import Any

from arckit.client import ArcKit


class AsyncArcKit:
    def __init__(self, **kwargs: Any):
        self._sync = ArcKit(**kwargs)
        self._loop = asyncio.get_event_loop()

    def __getattr__(self, name: str) -> Any:
        attr = getattr(self._sync, name)
        if not callable(attr) and not hasattr(attr, "__class__"):
            return attr
        return _AsyncProxy(attr, self._loop) if hasattr(attr, "__class__") else attr


class _AsyncProxy:
    """Proxies a sub-client; every method call becomes an awaitable."""

    def __init__(self, target: Any, loop: asyncio.AbstractEventLoop):
        self._target = target
        self._loop = loop

    def __getattr__(self, name: str) -> Any:
        attr = getattr(self._target, name)
        if not callable(attr):
            return attr

        async def _wrapper(*args: Any, **kwargs: Any) -> Any:
            return await self._loop.run_in_executor(None, lambda: attr(*args, **kwargs))

        return _wrapper
