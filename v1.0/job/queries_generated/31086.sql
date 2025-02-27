WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT
        m.id AS movie_id,
        CONCAT(h.movie_title, ' -> ', m.title) AS movie_title,
        h.level + 1
    FROM
        MovieHierarchy h
    JOIN
        aka_title m ON m.episode_of_id = h.movie_id
),
RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER(PARTITION BY EXTRACT(YEAR FROM m.production_year) ORDER BY m.production_year DESC) AS year_rank
    FROM
        aka_title m
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MoviesWithKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        aka_title m ON mk.movie_id = m.id
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.movie_id
),
TopMovies AS (
    SELECT
        rm.*,
        mk.keywords
    FROM
        RankedMovies rm
    LEFT JOIN
        MoviesWithKeywords mk ON rm.movie_id = mk.movie_id
    WHERE
        rm.year_rank <= 5
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    COALESCE(tm.keywords, 'No Keywords') AS keywords,
    CASE
        WHEN tm.production_year < 2010 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2010 AND 2019 THEN 'Contemporary'
        ELSE 'Recent'
    END AS era_category
FROM
    TopMovies tm
LEFT JOIN
    movie_info mi ON tm.movie_id = mi.movie_id
WHERE
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') 
    AND mi.info IS NOT NULL
ORDER BY
    tm.production_year DESC,
    tm.title ASC;
