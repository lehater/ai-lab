"""Minimal half-open interval overlap exercise: [start, end)."""


def intervals_overlap(left: tuple[int, int], right: tuple[int, int]) -> bool:
    """Return whether two valid half-open intervals share any instant."""
    a_start, a_end = left
    b_start, b_end = right
    if a_start >= a_end or b_start >= b_end:
        raise ValueError("interval start must be less than end")

    # Deliberate defect for the E2E pilot: touching endpoints are not overlap.
    return a_start < b_end and b_start <= a_end
