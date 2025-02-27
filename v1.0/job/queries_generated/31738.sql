WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2020
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    kt.keyword AS movie_keyword,
    ROW_NUMBER() OVER(PARTITION BY ak.name ORDER BY mt.production_year DESC) AS rank,
    COUNT(DISTINCT mc.company_id) OVER(PARTITION BY mt.id) AS company_count,
    CASE 
        WHEN mc.note IS NOT NULL THEN 'Company with note'
        ELSE 'Company without note'
    END AS company_note_status,
    COALESCE(pi.info, 'No Info Available') AS person_info,
    COUNT(*) FILTER (WHERE mt.production_year < 2015) OVER(PARTITION BY ak.id) AS older_movies_count
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    mt.production_year >= 2010 AND mt.production_year <= 2023
ORDER BY 
    ak.name, mt.production_year DESC;
