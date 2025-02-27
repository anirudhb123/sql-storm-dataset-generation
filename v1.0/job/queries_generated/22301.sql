WITH RECURSIVE movie_hierarchy AS (
    -- Recursive CTE to traverse movie links
    SELECT m.id AS movie_id, m.title AS movie_title, 
           COALESCE(m.note, 'No Note') AS movie_note, 
           1 AS depth
    FROM aka_title m
    WHERE m.production_year > 2000
    
    UNION ALL
    
    SELECT ml.linked_movie_id, lt.title, 
           COALESCE(lt.note, 'No Note') AS movie_note, 
           mh.depth + 1
    FROM movie_link ml
    JOIN title lt ON ml.linked_movie_id = lt.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COALESCE(mh.movie_title, 'N/A') AS linked_movie_title,
    COUNT(mh.movie_id) AS depth_links,
    STRING_AGG(DISTINCT mk.keyword, ', ') FILTER (WHERE mk.keyword IS NOT NULL) AS keywords,
    CASE 
        WHEN pi.info IS NULL THEN 'No Info'
        ELSE pi.info
    END AS person_information,
    COUNT(DISTINCT cw.id) AS distinct_roles_count,
    
    MAX(CASE 
        WHEN c24.role_id IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END) AS has_low_role
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN aka_title at ON ci.movie_id = at.id
LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN movie_info mi ON at.id = mi.movie_id
LEFT JOIN person_info pi ON ak.person_id = pi.person_id
LEFT JOIN movie_hierarchy mh ON mh.movie_id = at.id
LEFT JOIN role_type c24 ON ci.role_id = c24.id
JOIN complete_cast cc ON cc.movie_id = at.id
GROUP BY ak.name, at.title, pi.info
ORDER BY depth_links DESC, actor_name ASC
LIMIT 50;

-- Insight:
-- The above SQL query creates a comprehensive overview of actors, their movies,
-- linked movies, keywords, and person information, showing connections and roles
-- while applying a recursive CTE for linked movies, aggregated keywords, and conditional logic for handling NULL values.
