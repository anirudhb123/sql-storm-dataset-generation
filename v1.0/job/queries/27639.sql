WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN aka_name an ON ci.person_id = an.person_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE 
        m.production_year >= 2000 AND
        m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv_series')) 
    GROUP BY m.id, m.title, m.production_year, m.kind_id
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM RankedMovies
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.kind_id,
    tm.cast_count,
    tm.actors,
    tm.keywords
FROM TopMovies tm
WHERE rank <= 10
ORDER BY tm.cast_count DESC;
