
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
KeywordedMovies AS (
    SELECT 
        m.movie_id, 
        m.title, 
        m.actor_count, 
        k.keyword 
    FROM 
        RankedMovies m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    ORDER BY 
        m.actor_count DESC
)
SELECT 
    km.title AS movie_title,
    km.actor_count AS total_actors,
    STRING_AGG(DISTINCT km.keyword, ', ') AS keywords
FROM 
    KeywordedMovies km
GROUP BY 
    km.movie_id, km.title, km.actor_count
HAVING 
    COUNT(DISTINCT km.keyword) > 1
ORDER BY 
    total_actors DESC, movie_title;
