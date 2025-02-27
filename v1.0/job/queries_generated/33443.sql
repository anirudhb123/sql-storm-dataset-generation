WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(mh.depth) AS average_dependency_depth,
    STRING_AGG(DISTINCT t.title || ' (' || t.production_year || ')', ', ') AS related_movies
FROM 
    cast_info c
JOIN 
    aka_name a ON a.person_id = c.person_id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_title t ON t.id = c.movie_id
WHERE 
    a.name IS NOT NULL
    AND a.name != ''
    AND c.note IS NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC;

WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT mc.company_id) AS company_count,
        MAX(m.production_year) AS latest_year
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title
),
actor_ranked AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        RANK() OVER (PARTITION BY a.gender ORDER BY COUNT(c.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON c.person_id = a.person_id
    GROUP BY 
        a.id, a.name, a.gender
    HAVING 
        COUNT(c.movie_id) > 3
)

SELECT 
    ad.actor_name,
    md.title AS movie_title,
    md.latest_year,
    ad.actor_rank
FROM 
    movie_details md
JOIN 
    actor_ranked ad ON ad.actor_rank <= 5
WHERE 
    md.company_count > 2
ORDER BY 
    md.latest_year DESC, ad.actor_name;
