WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(c.movie_id) > 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    pa.actor_name,
    mk.keywords
FROM 
    RankedMovies rm
JOIN 
    PopularActors pa ON rm.movie_id = pa.actor_id 
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;