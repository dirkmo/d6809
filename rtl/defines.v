localparam // Registers on data bus
    DB_IR  = 0,
    DB_ARL = 1,
    DB_ARH = 2,
    DB_T   = 3,
    DB_A   = 4,
    DB_B   = 5,
    DB_XL  = 6,
    DB_XH  = 7,
    DB_YL  = 8,
    DB_YH  = 9,
    DB_CC  = 10,
    DB_PB  = 11, // postbyte
    DB_USH = 12,
    DB_USL = 13,
    DB_SPH = 14,
    DB_SPL = 15,
    DB_MEM = 16;

localparam // Registers on address bus
    AB_NONE   = 0,
    AB_PC     = 1,
    AB_AR     = 2,
    AB_DP_ARL = 3,
    AB_D      = 4,
    AB_SP     = 5,
    AB_US     = 6;
