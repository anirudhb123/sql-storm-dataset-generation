WITH RECURSIVE movie_hierarchy AS (
    -- Recursive CTE to find all movies linked to a particular movie
    SELECT m.id AS movie_id, m.title, 1 AS level
    FROM title m
    WHERE m.id = (
        SELECT id FROM title WHERE title = 'Inception'  -- Example movie

        LIMIT 1
    )
    
    UNION ALL
    
    SELECT m.linked_movie_id, t.title, mh.level + 1
    FROM movie_link m
    JOIN title t ON m.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON mh.movie_id = m.movie_id
)

SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    COALESCE(ci.kind, 'Unknown') AS role_type,
    COUNT(DISTINCT mw.keyword) AS keyword_count,
    SUM(mi.info_type_id) FILTER (WHERE it.info = 'Box Office') AS box_office_total,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY SUM(mi.info_type_id) DESC) AS top_role
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN movie_keyword mw ON t.id = mw.movie_id
LEFT JOIN movie_info mi ON t.id = mi.movie_id
LEFT JOIN info_type it ON mi.info_type_id = it.id
LEFT JOIN movie_hierarchy mh ON mh.movie_id = t.id
WHERE t.production_year > 2000
AND (ci.note IS NULL OR ci.note NOT LIKE '%uncredited%')
GROUP BY ak.name, t.title, ci.kind
HAVING COUNT(DISTINCT mw.keyword) > 3  -- Only movies with more than 3 unique keywords
ORDER BY actor_name, movie_title DESC;
