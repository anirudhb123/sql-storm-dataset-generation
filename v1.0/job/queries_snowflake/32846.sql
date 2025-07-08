WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(CAST(md.info AS text), 'No Info') AS additional_info,
    COUNT(c.role_id) OVER (PARTITION BY a.id) AS total_roles,
    ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY c.nr_order) AS role_order
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    movie_info md ON mt.id = md.movie_id AND md.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
WHERE 
    mt.production_year > 2000
    AND (mt.note IS NULL OR mt.note != 'Unreleased')
    AND EXISTS (
        SELECT 1 
        FROM movie_keyword mk
        WHERE mk.movie_id = mt.id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword IN ('Action', 'Drama'))
    )
    AND a.name NOT LIKE '%Test%'
ORDER BY 
    mt.production_year DESC,
    a.name;
