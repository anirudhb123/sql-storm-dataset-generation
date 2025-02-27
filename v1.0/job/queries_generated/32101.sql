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
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    a.id AS aka_id, 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS cast_count,
    AVG(CASE 
        WHEN pi.info_type_id IS NOT NULL THEN 1 
        ELSE 0 
    END) AS avg_info_type_present,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS role_order
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieHierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id AND pi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Biography%')
WHERE 
    a.name IS NOT NULL
    AND (m.production_year > 2010 OR m.production_year IS NULL)
GROUP BY 
    a.id, a.name, m.id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 1
ORDER BY 
    m.production_year DESC, role_order;
