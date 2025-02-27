WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m2.id AS movie_id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
)
SELECT 
    mh.title AS parent_movie_title,
    mh.production_year AS parent_movie_year,
    COUNT(DISTINCT mc.company_id) AS production_companies_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank_by_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    mh.level <= 2 
    AND (mc.note IS NULL OR mc.note <> 'N/A')
GROUP BY 
    mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    parent_movie_year DESC, rank_by_year;


