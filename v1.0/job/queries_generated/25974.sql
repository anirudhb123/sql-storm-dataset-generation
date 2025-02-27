WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_per_year
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
    AND 
        m.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        ta.name AS actor_name,
        ta.movie_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        TopActors ta ON ci.person_id = ta.person_id
)
SELECT 
    mw.movie_title,
    mw.production_year,
    mw.actor_name,
    mw.movie_count,
    COUNT(DISTINCT ci.note) AS unique_cast_notes
FROM 
    MoviesWithActors mw
LEFT JOIN 
    cast_info ci ON mw.movie_id = ci.movie_id
WHERE 
    mw.rank_per_year <= 3
GROUP BY 
    mw.movie_title, mw.production_year, mw.actor_name, mw.movie_count
ORDER BY 
    mw.production_year DESC, mw.movie_title, mw.actor_name;
