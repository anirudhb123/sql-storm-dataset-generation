WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS recent_movie_rank,
    COALESCE(NULLIF(cmt.note, ''), 'No additional info') AS company_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title t ON mh.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cmt ON mc.company_id = cmt.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year IS NOT NULL
    AND (t.production_year >= 2000 OR t.production_year IS NULL)
    AND ci.note IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, cmt.note
HAVING 
    COUNT(DISTINCT kc.keyword) > 1
ORDER BY 
    recent_movie_rank, a.name;

This SQL query utilizes various constructs including a recursive CTE to build a movie hierarchy based on linked movies, multiple outer joins to connect actors, their roles, keywords associated with movies, and any relevant information about the companies that produced those movies. It incorporates advanced logic including COALESCE for handling NULL values, string manipulations, window functions for ranking, and filters to sift through substantial data with multiple conditions.
