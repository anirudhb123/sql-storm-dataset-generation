WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
ActorsInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COALESCE(amc.movie_count, 0) AS movie_count,
        RANK() OVER (ORDER BY COALESCE(amc.movie_count, 0) DESC) AS actor_rank
    FROM 
        aka_name a
    LEFT JOIN 
        ActorMovieCount amc ON a.person_id = amc.person_id
)
SELECT 
    ti.title_id,
    ti.title,
    ti.production_year,
    ai.name AS actor_name,
    ai.movie_count,
    ai.actor_rank
FROM 
    RankedTitles ti
JOIN 
    cast_info ci ON ti.title_id = ci.movie_id
JOIN 
    ActorsInfo ai ON ci.person_id = ai.person_id
WHERE 
    ti.production_year >= 2000
  AND 
    (ai.movie_count > 5 OR ai.actor_rank <= 10)
ORDER BY 
    ti.production_year DESC, 
    ai.movie_count DESC, 
    ti.title ASC;
