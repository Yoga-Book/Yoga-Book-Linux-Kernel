---
name: kernel-driver-lifecycle-review
description: Audit Linux driver probe, failure unwind, asynchronous callbacks, removal and power-management lifetimes. Use for focused lifecycle review or bugs involving races, teardown, resource ownership, suspend or resume.
---

# Driver lifecycle review

Resolve the kernel root and follow AGENTS.md. Identify the device/bus and subsystem,
then read its MAINTAINERS profile and applicable driver documentation. Consult
Documentation/driver-api/driver-model/devres.rst, Documentation/driver-api/basics.rst,
Documentation/power/runtime_pm.rst and relevant locking/RCU/workqueue documentation
only as the driver's mechanisms require. Read the API implementation and callers
at the target revision; similar API names need not imply identical guarantees.

## Trace ownership and execution

Use CodeGraph first when indexed, then follow probe and every resource acquisition,
publication point, callback entry, error label, remove/shutdown and PM callback.
Build a compact ownership/state table when it clarifies the relationships:
resource, acquisition, possible users/context, quiescence point and final release.
Include users exposed through sysfs, device nodes and subsystem registration.

For each resource, determine who owns it and how long users can retain access.
Distinguish object allocation, device registration and hardware availability.
Managed allocation does not by itself stop callbacks or prove safe release order;
review devres ordering and interactions with manual cleanup and subsystem APIs.
Check probe deferral and every partial-initialization failure independently.

## Review transitions and races

For work, timers, IRQs, DMA, tasklets, threads and notifiers, trace both producers
and consumers. Determine how new activity is prevented, in-flight activity is
drained, and resources are freed. A drain can race with a producer requeuing work;
a reference can protect memory while the underlying device is already unusable.

Check the actual cancellation/synchronization API guarantees and allowed context.
Do not prescribe one shutdown order for every subsystem. Look for waits while
holding a lock needed by the callback being drained, sleep in atomic context,
missing publication ordering, refcount imbalance and accesses after unregister.
Account for shared interrupts, callback re-entry and externally held references
when applicable. State a concrete interleaving for a claimed race.

Compare system sleep, runtime PM, shutdown and remove semantics. Check power/clock
and regulator references, autosuspend interactions, wake IRQs, resume failure,
and restoring hardware state before restarting consumers. A successful cold probe
does not prove a successful resume, and remove is not synonymous with shutdown.

## Findings and validation

Classify findings by demonstrated impact and cite source locations, ownership
rules and a reachable failure path. Mark unproven concerns as hypotheses. Avoid
speculative synchronization changes or automatic replacement with managed APIs.
A review-only request does not authorize fixes.

Select focused tests: probe failure injection, repeated bind/unbind or module
load/unload, activity during removal, suspend/resume with traffic, and suitable
lockdep/KASAN/KCSAN checks. Execute disruptive device tests only within authorized
scope and with a recovery plan; otherwise provide instructions and state the gap.
Use kernel-validation for a broader matrix and kernel-development for authorized
implementation. Carry concrete lifecycle evidence into the patch rationale.
