WITH RankedMovies AS (
    SELECT
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_count
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    WHERE
        a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
        AND a.production_year > 2000
    GROUP BY
        a.id, a.title, a.production_year
),
MovieGenres AS (
    SELECT
        m.title,
        k.keyword,
        m.production_year
    FROM
        aka_title m
    INNER JOIN
        movie_keyword mk ON m.id = mk.movie_id
    INNER JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        k.keyword IS NOT NULL
        AND m.production_year BETWEEN 2010 AND 2020
),
FilteredMovies AS (
    SELECT
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        COUNT(DISTINCT mg.keyword) AS genre_count
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieGenres mg ON rm.movie_title = mg.title
    WHERE
        rm.rank_by_cast_count <= 5
        OR rm.cast_count > 50
    GROUP BY
        rm.movie_title, rm.production_year, rm.cast_count
)
SELECT
    DISTINCT
    fm.movie_title,
    fm.production_year,
    fm.cast_count,
    fm.genre_count,
    CASE 
        WHEN fm.genre_count > 1 THEN 'Diverse Genre'
        ELSE 'Single Genre'
    END AS genre_diversity,
    CASE
        WHEN CAST(fm.cast_count AS INTEGER) IS NULL THEN 'Unknown'
        WHEN fm.cast_count > 30 THEN 'Large Cast'
        WHEN fm.cast_count BETWEEN 15 AND 30 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM
    FilteredMovies fm
ORDER BY
    fm.production_year DESC,
    fm.cast_count DESC
LIMIT 10;

-- Hypothetical NULL handling to add depth
SELECT
    CASE 
        WHEN movie_title IS NULL THEN 'Movie Title Unknown'
        WHEN production_year IS NULL THEN 'Year Not Specified'
        ELSE 'Data Present'
    END AS title_status
FROM
    FilteredMovies
WHERE
    movie_title IS NULL OR production_year IS NULL;
