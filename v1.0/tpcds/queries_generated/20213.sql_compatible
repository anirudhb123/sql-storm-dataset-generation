
WITH RECURSIVE wealth_analysis AS (
    SELECT 
        hd_demo_sk,
        SUM(CASE WHEN c.c_birth_month = 1 THEN 1 ELSE 0 END) AS jan_births,
        SUM(CASE WHEN c.c_birth_month = 2 THEN 1 ELSE 0 END) AS feb_births,
        SUM(CASE WHEN c.c_birth_month = 3 THEN 1 ELSE 0 END) AS mar_births,
        SUM(CASE WHEN c.c_birth_month = 4 THEN 1 ELSE 0 END) AS apr_births,
        SUM(CASE WHEN c.c_birth_month = 5 THEN 1 ELSE 0 END) AS may_births,
        SUM(CASE WHEN c.c_birth_month = 6 THEN 1 ELSE 0 END) AS jun_births,
        SUM(CASE WHEN c.c_birth_month = 7 THEN 1 ELSE 0 END) AS jul_births,
        SUM(CASE WHEN c.c_birth_month = 8 THEN 1 ELSE 0 END) AS aug_births,
        SUM(CASE WHEN c.c_birth_month = 9 THEN 1 ELSE 0 END) AS sep_births,
        SUM(CASE WHEN c.c_birth_month = 10 THEN 1 ELSE 0 END) AS oct_births,
        SUM(CASE WHEN c.c_birth_month = 11 THEN 1 ELSE 0 END) AS nov_births,
        SUM(CASE WHEN c.c_birth_month = 12 THEN 1 ELSE 0 END) AS dec_births
    FROM 
        household_demographics hd
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd_demo_sk
),
zodiac_ranges AS (
    SELECT 
        1 AS zodiac_sign, 'Capricorn' AS sign_name, 20 AS end_day
    UNION ALL SELECT 2, 'Aquarius', 18
    UNION ALL SELECT 3, 'Pisces', 20
    UNION ALL SELECT 4, 'Aries', 20
    UNION ALL SELECT 5, 'Taurus', 20
    UNION ALL SELECT 6, 'Gemini', 20
    UNION ALL SELECT 7, 'Cancer', 22
    UNION ALL SELECT 8, 'Leo', 22
    UNION ALL SELECT 9, 'Virgo', 22
    UNION ALL SELECT 10, 'Libra', 22
    UNION ALL SELECT 11, 'Scorpio', 21
    UNION ALL SELECT 12, 'Sagittarius', 21
),
demographic_analysis AS (
    SELECT 
        hd.hd_demo_sk,
        d.ib_income_band_sk,
        SUM(CASE 
                WHEN c.c_birth_day <= zr.end_day THEN 1 
                ELSE 0 
            END) AS zodiac_population
    FROM 
        household_demographics hd
    LEFT JOIN income_band d ON hd.hd_income_band_sk = d.ib_income_band_sk
    LEFT JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN zodiac_ranges zr ON c.c_birth_month = zr.zodiac_sign
    GROUP BY 
        hd.hd_demo_sk, d.ib_income_band_sk
)
SELECT 
    dw.hd_demo_sk,
    dw.ib_income_band_sk,
    DENSE_RANK() OVER (PARTITION BY dw.ib_income_band_sk ORDER BY dw.zodiac_population DESC) AS demographic_rank,
    COUNT(CASE WHEN dw.zodiac_population > 10 THEN 1 END) AS significant_zodiac_counts
FROM 
    demographic_analysis dw
WHERE 
    dw.zodiac_population IS NOT NULL
GROUP BY 
    dw.hd_demo_sk, dw.ib_income_band_sk
HAVING 
    COUNT(CASE WHEN dw.zodiac_population > 10 THEN 1 END) > 1
ORDER BY 
    dw.ib_income_band_sk, demographic_rank;
