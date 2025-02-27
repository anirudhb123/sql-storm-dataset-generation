WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(mci.company_id), 0) AS company_count,
        1 AS level
    FROM
        aka_title m
    LEFT JOIN
        movie_companies mci ON m.id = mci.movie_id
    GROUP BY
        m.id, m.title, m.production_year
    UNION ALL
    SELECT
        lm.movie_id,
        lm.title,
        lm.production_year,
        COALESCE(SUM(mci.company_id), 0) AS company_count,
        level + 1
    FROM
        movie_hierarchy lm
    JOIN
        movie_link ml ON lm.movie_id = ml.movie_id
    LEFT JOIN
        movie_companies mci ON ml.linked_movie_id = mci.movie_id
    GROUP BY
        lm.movie_id, lm.title, lm.production_year, level
),
filtered_movies AS (
    SELECT
        h.movie_id,
        h.title,
        h.production_year,
        h.company_count,
        ROW_NUMBER() OVER (PARTITION BY h.production_year ORDER BY h.company_count DESC) AS rank
    FROM
        movie_hierarchy h
    WHERE
        h.production_year >= 2000
)
SELECT
    f.movie_id,
    f.title,
    f.production_year,
    f.company_count,
    NULLIF(f.company_count, 0) AS non_zero_company_count,
    CASE 
        WHEN f.rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS category
FROM
    filtered_movies f
LEFT JOIN
    cast_info ci ON f.movie_id = ci.movie_id
 WHERE
    f.company_count IS NOT NULL
    AND ci.role_id IS NOT NULL
ORDER BY
    f.production_year ASC, f.company_count DESC;
