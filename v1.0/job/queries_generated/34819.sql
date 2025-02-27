WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year BETWEEN 1990 AND 2023
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title AS m
    JOIN 
        movie_link AS ml ON m.id = ml.movie_id
    JOIN 
        movie_hierarchy AS mh ON ml.linked_movie_id = mh.movie_id
) 
SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(cast.aggregate_roles, 'No Roles Assigned') AS roles,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(xp.imdb_rating) AS average_rating,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS row_num
FROM 
    movie_hierarchy AS m
LEFT JOIN 
    complete_cast AS cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    (SELECT 
         movie_id,
         STRING_AGG(role_type.role, ', ') AS aggregate_roles
     FROM 
         cast_info AS ci
     JOIN 
         role_type ON ci.role_id = role_type.id
     GROUP BY 
         movie_id) AS cast ON m.movie_id = cast.movie_id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword AS kc ON mk.keyword_id = kc.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         AVG(CAST(info AS FLOAT)) AS imdb_rating
     FROM 
         movie_info AS mi
     WHERE 
         mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
     GROUP BY 
         movie_id) AS xp ON xp.movie_id = m.movie_id
GROUP BY 
    m.movie_id, m.title, m.production_year, cast.aggregate_roles
HAVING 
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY 
    m.production_year DESC, row_num;
