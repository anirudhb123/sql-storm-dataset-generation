WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m2.id AS parent_movie_id
    FROM 
        aka_title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    LEFT JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ml.linked_movie_id
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
)

SELECT 
    a.id AS actor_id,
    ak.name AS actor_name,
    ARRAY_AGG(DISTINCT mk.keyword) AS movie_keywords,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    MAX(mh.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT mh.movie_title, ', ') AS movie_titles,
    SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS featured_roles,
    COALESCE(MAX(i.info), 'No Info Available') AS additional_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
JOIN 
    movie_info i ON cc.movie_id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Misc Info')
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = c.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND ak.md5sum IS NOT NULL
GROUP BY 
    ak.id, ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 0
ORDER BY 
    total_movies DESC, latest_movie_year DESC
LIMIT 50;

