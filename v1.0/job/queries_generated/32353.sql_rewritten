WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
    
    UNION ALL

    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.linked_movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT mh.linked_movie_id) AS num_sequels,
    AVG(mk_count.keyword_count) AS avg_keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         COUNT(*) AS keyword_count
     FROM 
         movie_keyword
     GROUP BY 
         movie_id) mk_count ON t.id = mk_count.movie_id
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT mh.linked_movie_id) > 0
ORDER BY 
    num_sequels DESC,
    avg_keywords DESC
LIMIT 20;