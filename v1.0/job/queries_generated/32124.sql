WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keyword') AS keyword,
        1 AS level
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mk.linked_movie_id AS movie_id,
        lt.title AS movie_title,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keyword') AS keyword,
        mh.level + 1
    FROM 
        movie_hierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS lt ON ml.linked_movie_id = lt.id 
    LEFT JOIN 
        movie_keyword AS mk ON lt.id = mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.keyword,
    COUNT(DISTINCT c.person_id) AS actors_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    MAX(CASE WHEN m.production_year = (SELECT MAX(production_year) FROM aka_title) THEN 'Latest Release' ELSE NULL END) AS release_status
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    cast_info AS c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name AS a ON c.person_id = a.person_id
LEFT JOIN 
    aka_title AS m ON mh.movie_id = m.id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.keyword
HAVING 
    COUNT(DISTINCT c.person_id) > 0
ORDER BY 
    actors_count DESC, mh.movie_title;
