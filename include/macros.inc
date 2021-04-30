MACRO lb
    ASSERT \2 >= -128 && \2 < 256, "The value \2 is not 8-bit!"
    ASSERT \3 >= -128 && \3 < 256, "The value \3 is not 8-bit!"
    ld      \1, (LOW(\2) << 8) | LOW(\3)
ENDM
