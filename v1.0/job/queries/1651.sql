WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
ActorRoleCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.role_id) AS unique_roles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
)
SELECT 
    rm.actor_name,
    rm.movie_title,
    rm.production_year,
    COALESCE(ar.unique_roles, 0) AS unique_roles_count,
    CASE 
        WHEN rm.rn <= 3 THEN 'Top 3' 
        ELSE 'Other' 
    END AS movie_rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoleCounts ar ON rm.aka_id = ar.person_id
WHERE 
    rm.production_year > 2000
AND 
    rm.movie_title IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.actor_name ASC
FETCH FIRST 50 ROWS ONLY;
