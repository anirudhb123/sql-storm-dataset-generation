WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        movie_hierarchy AS mh ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS m ON m.id = ml.linked_movie_id
)
SELECT 
    mv.title AS primary_movie,
    mv.production_year,
    c.name AS company_name,
    COUNT(DISTINCT ca.person_id) AS actor_count,
    ARRAY_AGG(DISTINCT ak.name) AS actor_names,
    AVG(CASE 
            WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') 
            THEN CAST(mi.info AS numeric) 
            ELSE NULL 
        END) AS average_budget,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY mv.title) AS movie_rank
FROM 
    movie_hierarchy AS mv
LEFT JOIN 
    movie_companies AS mc ON mv.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS c ON mc.company_id = c.id
LEFT JOIN 
    complete_cast AS cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    aka_name AS ak ON ca.person_id = ak.person_id
LEFT JOIN 
    movie_info AS mi ON mv.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword AS mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
WHERE 
    mv.level = 1
GROUP BY 
    mv.movie_id, mv.title, mv.production_year, c.name
HAVING 
    COUNT(DISTINCT ca.person_id) > 5 AND 
    AVG(CASE 
            WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') 
            THEN CAST(mi.info AS numeric) 
            ELSE NULL 
        END) IS NOT NULL
ORDER BY 
    mv.production_year DESC, actor_count DESC;
