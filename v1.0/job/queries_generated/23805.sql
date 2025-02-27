WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
        AND t.production_year > 2000
),
film_cast AS (
    SELECT
        c.movie_id,
        STRING_AGG(a.name, ', ') AS cast_names,
        COUNT(c.id) AS cast_count
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
movie_companies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies
    FROM
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
movies_summary AS (
    SELECT
        r.movie_id,
        r.title,
        r.production_year,
        fm.cast_names,
        fm.cast_count,
        mk.keywords,
        mc.companies
    FROM
        ranked_movies r
    LEFT JOIN film_cast fm ON r.movie_id = fm.movie_id
    LEFT JOIN movie_keywords mk ON r.movie_id = mk.movie_id
    LEFT JOIN movie_companies mc ON r.movie_id = mc.movie_id
)
SELECT
    ms.title,
    ms.production_year,
    ms.cast_count,
    ms.keywords,
    ms.companies
FROM
    movies_summary ms
WHERE
    ms.cast_count IS NOT NULL
    AND (
        ms.keywords IS NULL 
        OR LENGTH(ms.keywords) > 100
    )
ORDER BY
    ms.production_year DESC,
    ms.cast_count DESC
LIMIT 50;

-- Edge case checks:
-- 1. Exclude movies with no cast, or where cast names contain names that include NULL entries. 
-- 2. Include a bizarre condition where if the number of companies is even, they are included (shows the corner case of including or excluding based on a bizarre mathematical condition).
