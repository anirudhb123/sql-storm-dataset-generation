
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        a.person_id,
        a.md5sum,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name, a.person_id, a.md5sum
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    ad.name AS leading_actor,
    ad.movie_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON ad.person_id IN (
        SELECT person_id 
        FROM aka_name 
        WHERE name LIKE '%Smith%'
    )
WHERE 
    rm.rank_within_year <= 5
  AND 
    rm.actor_count > 2
ORDER BY 
    rm.production_year DESC,
    rm.actor_count DESC;
