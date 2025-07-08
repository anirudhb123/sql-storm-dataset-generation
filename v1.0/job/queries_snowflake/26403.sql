
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') AS actor_names
    FROM
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM
        RankedMovies rm
    WHERE
        rm.cast_count > 5
)
SELECT
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.actor_names,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = f.movie_id) AS keyword_count,
    (SELECT LISTAGG(DISTINCT k.keyword, ', ') FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = f.movie_id) AS keywords
FROM
    FilteredMovies f
ORDER BY
    f.rank
LIMIT 10;
