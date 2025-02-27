WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    AND 
        t.production_year > 2000
),
actor_roles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
null_movies AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(mi.info, 'No Information') AS movie_info
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    WHERE 
        mi.info IS NULL
),
distinct_roles AS (
    SELECT DISTINCT
        actor_name,
        role_name
    FROM 
        actor_roles
)
SELECT 
    nm.title AS movie_title,
    nm.production_year,
    dr.actor_name,
    dr.role_name,
    ar.role_count,
    CASE 
        WHEN ar.role_count = 0 THEN 'No Roles'
        ELSE 'Roles Available'
    END AS role_availability
FROM 
    null_movies nm
LEFT JOIN 
    actor_roles ar ON nm.movie_id = ar.movie_id
FULL OUTER JOIN 
    distinct_roles dr ON ar.actor_name = dr.actor_name
WHERE 
    (nm.production_year IS NOT NULL OR dr.actor_name IS NOT NULL)
AND 
    (COALESCE(ar.role_count, 0) > 0 OR nm.movie_info LIKE '%suspense%')
ORDER BY 
    nm.production_year DESC, nm.title, dr.actor_name;

