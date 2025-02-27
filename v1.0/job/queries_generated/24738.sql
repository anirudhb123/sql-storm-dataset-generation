WITH Recursive_Actors AS (
    SELECT 
        ka.name AS actor_name, 
        ct.kind AS role_type,
        ci.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ka.name IS NOT NULL
),
Filtered_Movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
Subquery_Actors AS (
    SELECT 
        r.actor_name, 
        r.role_type,
        r.movie_id,
        r.actor_order,
        r.total_actors
    FROM 
        Recursive_Actors r
    WHERE 
        r.actor_order = 1
),
Comparative_Role_Counts AS (
    SELECT 
        movie_id, 
        COUNT(DISTINCT role_type) AS unique_roles
    FROM 
        Recursive_Actors
    GROUP BY 
        movie_id
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    fm.actor_count,
    COALESCE(SUM(CASE WHEN ra.actor_order = 1 THEN 1 ELSE 0 END), 0) AS solo_leads,
    cr.unique_roles AS distinct_role_types,
    string_agg(DISTINCT ra.actor_name, ', ') AS ensemble_cast
FROM 
    Filtered_Movies fm
LEFT JOIN 
    Subquery_Actors ra ON fm.movie_id = ra.movie_id
LEFT JOIN 
    Comparative_Role_Counts cr ON fm.movie_id = cr.movie_id
GROUP BY 
    fm.movie_id, fm.movie_title, fm.production_year, fm.actor_count, cr.unique_roles
ORDER BY 
    fm.production_year DESC, fm.actor_count DESC;
