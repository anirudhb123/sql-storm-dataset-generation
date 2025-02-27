WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        m.linked_movie_id,
        1 AS level
    FROM 
        movie_link m
    JOIN 
        title t ON m.movie_id = t.id
    WHERE 
        m.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title AS main_movie,
    m.production_year AS main_year,
    h.title AS sequel_title,
    h.production_year AS sequel_year,
    h.level AS sequel_level,
    COUNT(DISTINCT c.id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    COALESCE(gc.name, 'Unknown') AS genre,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    title m
LEFT JOIN 
    movie_link ml ON m.id = ml.movie_id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_hierarchy h ON ml.linked_movie_id = h.movie_id
LEFT JOIN 
    (SELECT 
         kind, description
     FROM 
         company_type) gc ON mc.company_type_id = gc.id
WHERE 
    m.production_year >= 2000
GROUP BY 
    m.title, m.production_year, h.title, h.production_year, h.level, gc.name
ORDER BY 
    main_year DESC, sequel_level ASC;

