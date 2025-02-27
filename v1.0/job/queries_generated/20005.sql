WITH
    ranked_movies AS (
        SELECT
            t.id AS movie_id,
            t.title,
            t.production_year,
            ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS year_rank
        FROM
            aka_title t
        WHERE
            t.production_year IS NOT NULL
    ),
    cast_counts AS (
        SELECT
            c.movie_id,
            COUNT(c.person_id) AS num_cast_members
        FROM
            cast_info c
        GROUP BY
            c.movie_id
    ),
    nulls_check AS (
        SELECT
            m.id AS movie_id,
            COALESCE(m.title, 'Unknown Title') AS movie_title,
            COALESCE(c.num_cast_members, 0) AS cast_member_count
        FROM
            ranked_movies m
        LEFT JOIN
            cast_counts c ON m.movie_id = c.movie_id
    ),
    filtered_movies AS (
        SELECT
            movie_id,
            movie_title,
            cast_member_count
        FROM
            nulls_check
        WHERE
            cast_member_count > 0 OR POSITION('Unknown' IN movie_title) > 0
    )
SELECT
    f.movie_id,
    f.movie_title,
    f.cast_member_count,
    k.keyword AS movie_keyword,
    COALESCE(c.name, 'No Company') AS company_name
FROM
    filtered_movies f
LEFT JOIN
    movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN
    company_name c ON mc.company_id = c.id
WHERE
    f.cast_member_count > (SELECT AVG(cast_member_count) FROM filtered_movies)
ORDER BY
    f.movie_title ASC,
    f.cast_member_count DESC
LIMIT 50;

-- Additional complex corner cases
WITH recursive movie_links AS (
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM
        movie_link ml
    UNION ALL
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        ml.depth + 1
    FROM
        movie_link ml
    JOIN
        movie_links ml_recursive ON ml.movie_id = ml_recursive.linked_movie_id
    WHERE
        ml_recursive.depth < 5  -- Limiting depth to prevent infinite recursion
)
SELECT DISTINCT
    f.movie_id,
    f.movie_title,
    ml.linked_movie_id,
    COUNT(*) OVER (PARTITION BY f.movie_id) AS linked_movie_count
FROM
    filtered_movies f
LEFT JOIN
    movie_links ml ON f.movie_id = ml.movie_id
ORDER BY
    f.movie_title, linked_movie_count DESC;

-- Handling NULL logic and obscure cases
SELECT
    f.movie_id,
    f.movie_title,
    CASE
        WHEN f.cast_member_count IS NULL THEN 'Cast Missing'
        WHEN f.cast_member_count < 3 THEN 'Few Cast'
        ELSE 'Adequate Cast'
    END AS cast_status,
    COALESCE(NULLIF(k.keyword, ''), 'No Keyword') AS keyword_status
FROM
    filtered_movies f
LEFT JOIN
    movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id;
This SQL query draws upon advanced SQL features with CTEs for recursive relationships and aggregates, demonstrating outer joins and null handling while emphasizing both performance benchmarks and intricate dataset relationships within a movie database.
