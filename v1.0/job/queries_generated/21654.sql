WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM
        aka_title mt
    LEFT JOIN
        cast_info ci ON mt.id = ci.movie_id
    WHERE
        mt.production_year IS NOT NULL
    GROUP BY
        mt.id, mt.title, mt.production_year
),

TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank_by_cast <= 5
),

KeyWordStats AS (
    SELECT
        kw.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM
        keyword kw
    LEFT JOIN
        movie_keyword mk ON kw.id = mk.keyword_id
    GROUP BY
        kw.keyword
    HAVING
        COUNT(mk.movie_id) > 1
),

TitleCount AS (
    SELECT
        k.keyword,
        COUNT(DISTINCT t.id) AS title_count
    FROM
        KeyWordStats k
    JOIN
        movie_keyword mk ON mk.keyword_id = k.id
    JOIN
        title t ON t.id = mk.movie_id
    GROUP BY
        k.keyword
    HAVING
        COUNT(DISTINCT t.id) > 2
)
SELECT
    tm.title,
    tm.production_year,
    kc.keyword,
    kc.movie_count,
    tc.title_count,
    COALESCE(tc.title_count, 0) AS adjusted_title_count,
    CASE
        WHEN COALESCE(tc.title_count, 0) > 5 THEN 'High'
        WHEN COALESCE(tc.title_count, 0) BETWEEN 3 AND 5 THEN 'Medium'
        WHEN COALESCE(tc.title_count, 0) < 3 THEN 'Low'
        ELSE 'No Data'
    END AS title_count_category
FROM
    TopMovies tm
LEFT JOIN
    KeyWordStats kc ON kc.movie_count = tm.movie_id
LEFT JOIN
    TitleCount tc ON tc.keyword = kc.keyword
WHERE
    tm.production_year IN (SELECT DISTINCT production_year FROM aka_title WHERE production_year < 2000)
ORDER BY
    tm.production_year DESC,
    adjusted_title_count DESC
FETCH FIRST 10 ROWS ONLY;
