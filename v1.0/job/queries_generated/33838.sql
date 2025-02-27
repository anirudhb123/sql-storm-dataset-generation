WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_movie_id,
        ARRAY[mt.title] AS movie_path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_movie_id,
        mh.movie_path || m.title
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.parent_movie_id,
    mh.movie_path,
    COUNT(DISTINCT c.id) AS num_cast_members,
    SUM(CASE WHEN pi.info LIKE '%award%' THEN 1 ELSE 0 END) AS num_awards,
    AVG(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year ELSE NULL END) AS avg_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(c2.kind, 'Not Specified') AS company_type,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS rn
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_type c2 ON mc.company_type_id = c2.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'awards')
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
GROUP BY 
    ak.name, mt.title, mh.parent_movie_id, mh.movie_path, c2.kind
HAVING 
    COUNT(DISTINCT c.id) > 5
ORDER BY 
    num_awards DESC, num_cast_members DESC;
