WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_year,
        COUNT(DISTINCT c.person_id) AS num_actors
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
ActorInfo AS (
    SELECT 
        ka.name AS actor_name,
        k.keyword AS actor_keyword,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY ka.name) AS actor_rank
    FROM 
        cast_info c
    INNER JOIN 
        aka_name ka ON c.person_id = ka.person_id
    LEFT JOIN 
        movie_keyword k ON c.movie_id = k.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.num_actors,
    ai.actor_name,
    ai.actor_keyword
FROM 
    RankedMovies rm
FULL OUTER JOIN 
    ActorInfo ai ON rm.movie_id = ai.movie_id
WHERE 
    rm.rank_year <= 5 OR ai.actor_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.title, ai.actor_rank
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
