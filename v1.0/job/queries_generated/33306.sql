WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    COUNT(ci.id) AS total_cast,
    AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS note_present_ratio,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON mt.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON mt.movie_id = mi.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.movie_title, mt.production_year
HAVING 
    SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) > 5
ORDER BY 
    mt.production_year DESC, total_cast DESC;
