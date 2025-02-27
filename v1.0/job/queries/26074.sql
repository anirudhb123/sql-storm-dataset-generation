WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS genre,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rank
    FROM
        aka_title m
    JOIN
        movie_keyword mk ON m.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    GROUP BY
        m.id, m.title, m.production_year, k.keyword
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        genre,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),

ActorsInfo AS (
    SELECT
        a.id AS actor_id,
        a.name,
        a.md5sum,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        STRING_AGG(DISTINCT tm.genre, ', ') AS genres
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        TopMovies tm ON ci.movie_id = tm.movie_id
    GROUP BY
        a.id, a.name, a.md5sum
)

SELECT 
    ai.actor_id,
    ai.name,
    ai.movies_count,
    ai.genres
FROM 
    ActorsInfo ai
WHERE 
    ai.movies_count > 3
ORDER BY 
    ai.movies_count DESC;
