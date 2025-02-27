WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order DESC) as role_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) as actor_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info b ON a.id = b.movie_id
    GROUP BY 
        a.title, a.production_year
),
ActorDetails AS (
    SELECT 
        aka.name AS actor_name,
        a.id AS movie_id,
        a.title AS movie_title,
        r.role_rank,
        r.actor_count,
        CASE 
            WHEN a.production_year IS NULL THEN 'Unknown Year' 
            ELSE CAST(a.production_year AS TEXT) 
        END AS movie_year
    FROM 
        RankedMovies r
    JOIN 
        cast_info c ON r.id = c.movie_id
    JOIN 
        aka_name aka ON c.person_id = aka.person_id
)
SELECT 
    ad.actor_name,
    ad.movie_title,
    ad.movie_year,
    ad.role_rank,
    ad.actor_count,
    CASE 
        WHEN ad.actor_count > 10 THEN 'Ensemble Cast' 
        WHEN ad.role_rank = 1 THEN 'Lead' 
        ELSE 'Supporting' 
    END AS role_description
FROM 
    ActorDetails ad
WHERE 
    ad.movie_year <> 'Unknown Year'
AND 
    ad.actor_name IS NOT NULL
ORDER BY 
    ad.actor_count DESC, ad.role_rank ASC;

-- The above query does the following:
-- 1. Creates a CTE 'RankedMovies' that ranks movies by the order of their cast.
-- 2. Calculates the count of distinct actors in each movie.
-- 3. In the 'ActorDetails' CTE, we join the ranked movies with actor details.
-- 4. The final selection includes a derived column that categorizes the actor's role based on conditions.
-- 5. It filters out actors with unknown year and null names, ordering results by count of actors.

-- This query takes advantage of window functions, common table expressions (CTEs), and outer joins, 
-- while also exploring NULL logic and constructed semantics for actor classification.
