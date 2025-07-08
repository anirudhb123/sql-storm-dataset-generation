
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ca.person_id AS actor_id,
        ca.movie_id,
        1 AS level
    FROM 
        cast_info ca
    WHERE 
        ca.role_id = (SELECT id FROM role_type WHERE role = 'Main Actor')
    
    UNION ALL
    
    SELECT 
        ca.person_id,
        ca.movie_id,
        ah.level + 1
    FROM 
        cast_info ca
    JOIN 
        actor_hierarchy ah ON ca.movie_id = ah.movie_id
    WHERE 
        ca.role_id != (SELECT id FROM role_type WHERE role = 'Main Actor')
),

movie_info_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),

actor_movie_stats AS (
    SELECT 
        ah.actor_id,
        am.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ah.actor_id ORDER BY am.production_year DESC) AS rn,
        (SELECT COUNT(*) FROM actor_hierarchy a WHERE a.movie_id = am.movie_id) AS total_actors
    FROM 
        actor_hierarchy ah
    JOIN 
        aka_title am ON ah.movie_id = am.id
)

SELECT 
    a.actor_id,
    n.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    md.company_count,
    a.total_actors,
    CASE 
        WHEN a.total_actors > 10 THEN 'Large Cast'
        WHEN a.total_actors BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    actor_movie_stats a
JOIN 
    aka_name n ON a.actor_id = n.person_id
JOIN 
    movie_info_details md ON a.movie_id = md.movie_id
JOIN 
    aka_title m ON md.movie_id = m.id
WHERE 
    a.rn = 1
    AND m.production_year BETWEEN 1990 AND 2020
    AND n.name IS NOT NULL
ORDER BY 
    m.production_year DESC,
    n.name;
