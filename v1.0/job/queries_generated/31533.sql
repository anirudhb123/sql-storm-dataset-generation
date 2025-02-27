WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
)

SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    a.name AS actor_name,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    SUM(CASE WHEN c.kind_id IS NOT NULL THEN 1 ELSE 0 END) AS has_characters,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_order,
    COALESCE(info.info, 'No additional info') AS additional_info
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    movie_info_idx info ON mi.info_type_id = info.info_type_id
WHERE 
    m.production_year IS NOT NULL
    AND (m.title LIKE '%Action%' OR m.title LIKE '%Adventure%')
GROUP BY 
    m.id, a.name, info.info
HAVING 
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY 
    m.production_year DESC, m.title;
