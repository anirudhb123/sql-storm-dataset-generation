WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.id IN (SELECT linked_movie_id FROM movie_link WHERE link_type_id = 1)  

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id, 
        mt.title, 
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON mt.id = ml.linked_movie_id
)

SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(cc.person_id) AS total_cast,
    SUM(CASE WHEN cc.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes,
    AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) * 100 AS female_percentage,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    aka_name a
JOIN 
    cast_info cc ON a.person_id = cc.person_id
JOIN 
    aka_title t ON cc.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    name p ON cc.person_id = p.imdb_id
WHERE 
    t.production_year >= 2000
    AND (cc.note IS NULL OR cc.note NOT LIKE '%uncredited%')
GROUP BY 
    a.id, a.name, t.title, t.production_year
HAVING 
    COUNT(cc.person_id) > 0 OR SUM(CASE WHEN cc.note IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    movie_title, aka_name;