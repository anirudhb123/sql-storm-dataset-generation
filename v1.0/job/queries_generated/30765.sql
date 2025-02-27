WITH RECURSIVE cte_movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        t.title AS parent_title,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        aka_title t ON m.episode_of_id = t.id
    WHERE 
        m.episode_of_id IS NOT NULL

    UNION ALL

    SELECT 
        c.movie_id,
        c.title,
        c.production_year,
        h.title AS parent_title,
        h.level + 1
    FROM 
        aka_title c
    JOIN 
        cte_movie_hierarchy h ON c.episode_of_id = h.movie_id
)
SELECT 
    a.name AS actor_name,
    COALESCE(mh.parent_title, 'None') AS parent_title,
    mh.title AS movie_title,
    mh.production_year,
    SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mh.movie_id) AS number_of_roles,
    COUNT(DISTINCT ki.keyword) FILTER (WHERE ki.keyword IS NOT NULL) AS unique_keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY a.name) AS name_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    cte_movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    a.name IS NOT NULL
AND 
    mh.production_year >= 2000
GROUP BY 
    a.name, mh.parent_title, mh.title, mh.production_year
HAVING 
    COUNT(ci.movie_id) > 1
ORDER BY 
    mh.production_year DESC, number_of_roles DESC, name_rank;
