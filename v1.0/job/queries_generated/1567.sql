WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY t.title ORDER BY ak.name) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
)
SELECT 
    rm.production_year,
    rm.title,
    rm.actor_count,
    ad.actor_name,
    ad.actor_rank,
    CASE 
        WHEN rm.actor_count > 5 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    JSON_AGG(ad.actor_name) FILTER (WHERE ad.actor_rank <= 3) AS top_actors
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.title = ad.movie_title AND rm.production_year = ad.production_year
WHERE 
    rm.rank <= 5
GROUP BY 
    rm.production_year, rm.title, rm.actor_count
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
