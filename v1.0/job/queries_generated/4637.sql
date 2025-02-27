WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        km.keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
actor_roles AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    COUNT(DISTINCT m.keyword) AS total_keywords,
    MAX(md.production_year) AS last_movie_year,
    CASE 
        WHEN COUNT(DISTINCT mc.movie_id) = 0 THEN 'No films'
        ELSE 'Active actor'
    END AS actor_status
FROM 
    aka_name a
LEFT JOIN 
    cast_info mc ON a.person_id = mc.person_id
LEFT JOIN 
    movie_details md ON mc.movie_id = md.movie_id
LEFT JOIN 
    actor_roles ar ON a.person_id = ar.person_id
WHERE 
    a.name_pcode_cf IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5 
ORDER BY 
    last_movie_year DESC NULLS LAST;
