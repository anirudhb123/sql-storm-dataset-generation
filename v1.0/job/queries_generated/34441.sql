WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
  
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT
    ah.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    COUNT(DISTINCT c.role_id) FILTER (WHERE c.note IS NOT NULL) AS role_count,
    MIN(tr.name) AS first_role,
    ROW_NUMBER() OVER (PARTITION BY ah.person_id ORDER BY COUNT(DISTINCT kw.keyword) DESC) AS actor_ranking,
    CASE
        WHEN COUNT(DISTINCT kw.keyword) >= 5 THEN 'Expert'
        ELSE 'Novice'
    END AS actor_expertise
FROM 
    aka_name ah
LEFT JOIN 
    cast_info c ON c.person_id = ah.person_id
LEFT JOIN 
    movie_hierarchy mt ON mt.movie_id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN 
    role_type tr ON tr.id = c.role_id
GROUP BY 
    ah.name, mt.title, mt.production_year, ah.person_id
HAVING 
    COUNT(DISTINCT kw.keyword) > 0
ORDER BY 
    actor_expertise DESC,
    actor_ranking;
