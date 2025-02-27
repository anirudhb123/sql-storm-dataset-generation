WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        am.title AS movie_title,
        am.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title am ON ci.movie_id = am.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.actor_count,
    ai.actor_name,
    ai.actor_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON rm.title = ai.movie_title AND rm.production_year = ai.production_year
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC, 
    ai.actor_rank
LIMIT 50;
