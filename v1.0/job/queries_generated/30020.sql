WITH RECURSIVE related_movies AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.title ILIKE '%adventure%'
    UNION ALL
    SELECT
        linked_movie.linked_movie_id,
        l.title,
        l.production_year,
        depth + 1
    FROM
        related_movies r
    JOIN movie_link linked_movie ON r.movie_id = linked_movie.movie_id
    JOIN aka_title l ON linked_movie.linked_movie_id = l.movie_id
    WHERE
        depth < 3
),
movie_cast AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id
),
movie_info_detailed AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        COALESCE(m.cast_count, 0) AS cast_count,
        COALESCE(m.cast_names, 'No Cast') AS cast_names,
        CASE
            WHEN t.production_year IS NOT NULL AND t.production_year < 2000 THEN 'Classic'
            ELSE 'Modern'
        END AS era
    FROM
        aka_title t
    LEFT JOIN movie_cast m ON t.id = m.movie_id
)
SELECT
    r.movie_id,
    r.title,
    r.production_year,
    md.era,
    md.cast_count,
    md.cast_names
FROM
    related_movies r
JOIN movie_info_detailed md ON r.movie_id = md.id
ORDER BY
    r.production_year DESC,
    md.cast_count DESC;
