WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_count
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN
        cast_info c ON c.movie_id = t.id
    WHERE
        t.kind_id IN (1, 2)  
    GROUP BY
        t.id, t.title, t.production_year
),
distinct_names AS (
    SELECT DISTINCT
        a.person_id,
        a.name,
        COALESCE(a.name_pcode_cf, 'UNKNOWN') AS name_code
    FROM
        aka_name a
    WHERE
        a.name IS NOT NULL AND a.name != ''
),
movie_name_counts AS (
    SELECT
        mv.movie_id,
        COUNT(DISTINCT n.name) AS unique_name_count
    FROM
        movie_info mv
    JOIN
        distinct_names n ON mv.movie_id = n.person_id
    GROUP BY
        mv.movie_id
)
SELECT
    m.title,
    m.production_year,
    m.rank_count,
    mn.unique_name_count,
    CASE
        WHEN mn.unique_name_count IS NULL THEN 'No Names'
        ELSE CAST(mn.unique_name_count AS TEXT)
    END AS name_count,
    STRING_AGG(DISTINCT c.note, ', ') AS cast_notes,
    DENSE_RANK() OVER (PARTITION BY m.production_year ORDER BY m.rank_count DESC) AS dense_rank
FROM
    ranked_movies m
LEFT JOIN
    movie_name_counts mn ON m.movie_id = mn.movie_id
LEFT JOIN
    cast_info c ON c.movie_id = m.movie_id
WHERE
    m.rank_count <= 5  
GROUP BY
    m.movie_id, m.title, m.production_year, mn.unique_name_count, m.rank_count
ORDER BY
    m.production_year DESC, m.rank_count DESC;