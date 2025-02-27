WITH Recursive_CTE AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        r.role AS role_type
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    UNION ALL
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        r.role AS role_type
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.person_id
    JOIN 
        role_type r ON cc.subject_id = r.id
    WHERE 
        cc.status_id = 1
),
Aggregated_Data AS (
    SELECT 
        production_year,
        COUNT(DISTINCT title) AS total_movies,
        COUNT(DISTINCT actor_name) AS total_actors,
        STRING_AGG(DISTINCT role_type, ', ') AS roles
    FROM 
        Recursive_CTE
    GROUP BY 
        production_year
)
SELECT 
    ad.production_year,
    ad.total_movies,
    ad.total_actors,
    ad.roles
FROM 
    Aggregated_Data ad
WHERE 
    ad.total_movies > 10
ORDER BY 
    ad.production_year DESC;
