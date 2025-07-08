
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_movies,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorInfo AS (
    SELECT 
        ak.person_id, 
        ak.name, 
        COUNT(ci.movie_id) AS movie_count,
        MAX(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS has_notes
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    m.actors,
    m.actor_count,
    ai.name AS actor_name,
    ai.movie_count,
    ai.has_notes,
    (CASE 
         WHEN m.actor_count = 0 THEN 'no actors'
         WHEN ai.has_notes = 1 THEN 'has notes'
         ELSE 'no notes' 
     END) AS note_status
FROM 
    RankedMovies m
JOIN 
    ActorInfo ai ON ai.movie_count > 2  
WHERE 
    m.rank_movies <= 5  
    AND m.actor_count IS NOT NULL  
ORDER BY 
    m.production_year DESC,
    m.actor_count DESC
LIMIT 20;
