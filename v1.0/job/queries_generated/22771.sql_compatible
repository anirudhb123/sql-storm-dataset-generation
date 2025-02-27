
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorNames AS (
    SELECT 
        an.person_id,
        STRING_AGG(DISTINCT an.name, ', ' ORDER BY an.name) AS actor_names
    FROM 
        aka_name an
    LEFT JOIN 
        cast_info ci ON an.person_id = ci.person_id
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'actor')
    GROUP BY 
        an.person_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(rm.movie_rank, 0) AS rank,
    COALESCE(an.actor_names, 'Unknown') AS actors
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorNames an ON rm.movie_id = (SELECT cc.movie_id FROM complete_cast cc WHERE cc.subject_id = an.person_id LIMIT 1)
WHERE 
    rm.movie_rank <= 5 
ORDER BY 
    rm.production_year DESC,
    rank;
