WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        0 AS level, 
        mt.production_year,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        at.title AS movie_title, 
        mh.level + 1 AS level,
        at.production_year,
        mh.movie_id AS parent_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.level,
    mh.production_year,
    coalesce(cb.name, 'Unknown Company') AS company_name,
    COUNT(DISTINCT c.id) AS cast_count,
    AVG(COALESCE(mi.info_type_id, 0)) AS avg_info_type_id,
    (CASE 
        WHEN mh.production_year < 2000 THEN 'Classic' 
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
     END) AS movie_age_category,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cb ON mc.company_id = cb.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mh.production_year IS NOT NULL 
    AND (cb.country_code IS NULL OR cb.country_code <> 'USA')
GROUP BY 
    mh.movie_id, 
    mh.movie_title, 
    mh.level, 
    mh.production_year, 
    cb.name
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    mh.production_year DESC, 
    mh.movie_title;
