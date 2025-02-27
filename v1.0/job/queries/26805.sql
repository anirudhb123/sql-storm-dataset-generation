
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title, 
        m.production_year,
        COUNT(c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id,
        m.title,
        m.production_year
    ORDER BY 
        actor_count DESC
    LIMIT 10
),
KeywordMovies AS (
    SELECT 
        m.movie_id, 
        m.title, 
        m.production_year,
        k.keyword
    FROM 
        RankedMovies m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rm.movie_id,
    rm.title AS movie_title,
    rm.production_year,
    rm.actor_count,
    rm.actor_names,
    STRING_AGG(DISTINCT km.keyword, ', ') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordMovies km ON rm.movie_id = km.movie_id
GROUP BY 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    rm.actor_count, 
    rm.actor_names
ORDER BY 
    rm.actor_count DESC;
