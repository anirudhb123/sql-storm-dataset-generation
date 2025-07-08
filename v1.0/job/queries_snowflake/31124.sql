
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.id) AS cast_count,
    AVG(CASE WHEN p.info IS NOT NULL THEN 1 ELSE 0 END) AS actor_info_presence,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT c.id) DESC) AS movie_rank,
    (SELECT COUNT(DISTINCT ci2.person_id)
     FROM cast_info ci2 
     WHERE ci2.movie_id = t.id AND ci2.role_id IN 
         (SELECT id FROM role_type WHERE role LIKE '%lead%')
    ) AS lead_actors
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info p ON p.person_id = a.person_id
WHERE 
    t.production_year >= 2000
    AND (a.name LIKE '%Smith%' OR a.name LIKE '%Jones%')
GROUP BY 
    a.name, t.id, t.title, t.production_year
ORDER BY 
    t.production_year DESC, 
    actor_name ASC;
