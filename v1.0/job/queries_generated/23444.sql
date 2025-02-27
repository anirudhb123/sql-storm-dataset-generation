WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        CAST(NULL AS text) AS parent_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
  
    UNION ALL
  
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name,
    mt.movie_id,
    mt.title,
    mt.production_year,
    COALESCE(ai.info, 'No Info') AS additional_info,
    COUNT(DISTINCT ca.id) AS cast_count,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names,
    SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS production_company_count,
    MAX(CASE WHEN ct.kind = 'Distributor' THEN co.name END) AS distributor_name,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ca.id) DESC) AS rank
FROM 
    MovieHierarchy mt
LEFT JOIN 
    complete_cast cc ON mt.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    aka_name ak ON ca.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mt.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON mt.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    (SELECT movie_id, info FROM movie_info WHERE note IS NOT NULL) ai ON mt.movie_id = ai.movie_id
WHERE 
    mt.level <= 3
GROUP BY 
    ak.name, mt.movie_id, mt.title, mt.production_year, ai.info
HAVING 
    COUNT(DISTINCT ca.id) > 0 AND
    MIN(mt.production_year) > 2000 AND
    MAX(CASE WHEN ct.kind = 'Distributor' THEN co.name END) IS NOT NULL
ORDER BY 
    mt.production_year DESC, 
    rank ASC, 
    COUNT(DISTINCT ca.id) DESC;
