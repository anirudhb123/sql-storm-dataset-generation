WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        mt.production_year,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ct.kind) AS company_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mh.movie_id, 
        mh.title,
        mh.production_year,
        mh.company_type,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.company_type) AS company_rank
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    a.id AS actor_id, 
    a.name AS actor_name, 
    mh.title AS movie_title,
    mh.production_year, 
    mh.company_type, 
    COUNT(DISTINCT mc.company_id) AS total_companies,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    AVG(pi.info IS NOT NULL AND pi.info != '') AS info_presence_ratio
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info pi ON mh.movie_id = pi.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
WHERE 
    a.name IS NOT NULL
    AND (mh.company_type IS NULL OR mh.company_type = 'Distributor')
    AND (mh.production_year < 2000 OR mh.production_year IS NOT NULL)
GROUP BY 
    a.id, a.name, mh.title, mh.production_year, mh.company_type
HAVING 
    COUNT(DISTINCT mk.keyword) > 3 
ORDER BY 
    info_presence_ratio DESC, total_companies DESC
LIMIT 10;
