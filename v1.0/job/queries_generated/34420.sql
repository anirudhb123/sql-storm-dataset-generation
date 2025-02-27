WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON m.episode_of_id = mh.movie_id
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(DISTINCT CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN pi.info END) AS avg_rating,
    SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS cast_count,
    GROUP_CONCAT(DISTINCT ak.name) AS actor_names
FROM 
    movie_keyword mk
JOIN 
    movie_info mi ON mk.movie_id = mi.movie_id
JOIN 
    MovieHierarchy mh ON mk.movie_id = mh.movie_id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.id = c.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = c.person_id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
WHERE 
    mk.keyword IS NOT NULL
    AND mh.production_year BETWEEN 1990 AND 2020
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    movie_count DESC;
