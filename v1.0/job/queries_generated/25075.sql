WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordCount AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        RankedMovies m ON m.movie_id = mk.movie_id
    GROUP BY 
        m.movie_id
),
NotableMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rk.keyword_count,
        ARRAY_LENGTH(
            STRING_TO_ARRAY(rm.actor_names, ', '), 
            1
        ) AS unique_actor_count
    FROM 
        RankedMovies rm
    JOIN 
        KeywordCount rk ON rm.movie_id = rk.movie_id
    WHERE 
        rm.production_year >= 2000 AND 
        rk.keyword_count > 5
)
SELECT 
    nm.title,
    nm.production_year,
    nm.actor_count,
    nm.unique_actor_count,
    'Actors: ' || nm.actor_names AS actor_list
FROM 
    NotableMovies nm
ORDER BY 
    nm.production_year DESC, 
    nm.actor_count DESC
LIMIT 10;
