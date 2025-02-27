WITH MovieStatistics AS (
    SELECT
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast_count,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) * 100 AS cast_with_notes_percentage
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN
        movie_keyword mk ON at.movie_id = mk.movie_id
    WHERE
        at.production_year IS NOT NULL
    GROUP BY
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT
        ms.title_id,
        ms.title,
        ms.production_year,
        ms.total_cast_count,
        ms.total_keywords,
        RANK() OVER (ORDER BY ms.total_cast_count DESC) AS cast_rank
    FROM
        MovieStatistics ms
    WHERE
        ms.total_cast_count > 0
),
FilteredMovies AS (
    SELECT
        tm.title_id,
        tm.title,
        tm.production_year,
        tm.total_cast_count,
        tm.total_keywords
    FROM
        TopMovies tm
    WHERE
        tm.cast_rank <= 10
)
SELECT
    f.title,
    f.production_year,
    f.total_cast_count,
    f.total_keywords,
    COALESCE(NULLIF(f.total_keywords, 0), 1) AS dummy_keywords,
    CASE
        WHEN f.total_cast_count > 20 THEN 'Big Cast'
        WHEN f.total_cast_count BETWEEN 10 AND 20 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = f.title_id
        AND LOWER(mi.info) LIKE '%award%'
    ) AS has_award_info
FROM
    FilteredMovies f
LEFT JOIN
    aka_title ak ON ak.movie_id = f.title_id
LEFT JOIN
    movie_info idx ON idx.movie_id = f.title_id
WHERE
    ak.production_year BETWEEN 1990 AND 2023
ORDER BY
    f.total_cast_count DESC,
    f.total_keywords ASC
LIMIT 5;