WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
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
ActorDetails AS (
    SELECT 
        a.name,
        ac.movie_count,
        ROW_NUMBER() OVER (ORDER BY ac.movie_count DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        ActorMovieCount ac ON a.person_id = ac.person_id
    WHERE 
        a.name IS NOT NULL
        AND ac.movie_count > 5
)
SELECT 
    ad.name AS actor_name,
    ad.movie_count,
    rm.title AS movie_title,
    rm.production_year,
    (SELECT COUNT(DISTINCT c.company_id) 
     FROM movie_companies c 
     WHERE c.movie_id = rm.movie_id) AS company_count,
    CASE 
        WHEN rm.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(rm.production_year AS VARCHAR)
    END AS production_year_display
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.movie_id IN (SELECT DISTINCT ci.movie_id FROM cast_info ci WHERE ci.person_id IN (SELECT person_id FROM aka_name WHERE name = ad.name))
WHERE 
    ad.actor_rank <= 10 
    OR rm.year_rank <= 3
ORDER BY 
    ad.movie_count DESC, rm.production_year DESC;
