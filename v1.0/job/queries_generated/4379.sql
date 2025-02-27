WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    ai.name AS actor_name,
    ai.movie_count,
    ai.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON rm.movie_id = ai.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title ASC;
