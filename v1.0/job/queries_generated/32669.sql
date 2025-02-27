WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL 

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ka.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    AVG(COALESCE(CAST(mk.keyword AS VARCHAR), 'N/A')::text) AS average_keyword_length,
    ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ka.name) AS row_num,
    COALESCE(info.info, 'No info available') AS additional_info
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name ka ON cc.subject_id = ka.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info info ON mh.movie_id = info.movie_id AND info.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Description' LIMIT 1
    )
WHERE 
    ka.name IS NOT NULL
    AND mh.level <= 3
    AND mt.production_year IS NOT NULL
GROUP BY 
    ka.name, mt.title, mt.production_year, info.info
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    mt.production_year DESC, ka.name;
