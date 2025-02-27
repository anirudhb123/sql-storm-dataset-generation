WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mc.company_id,
        mt.production_year,
        ARRAY[mt.title] AS title_path,
        1 AS depth
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mc.company_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mt.title,
        mc.company_id,
        mt.production_year,
        mh.title_path || mt.title,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mc.company_id IS NOT NULL
)
SELECT 
    bh.title,
    bh.production_year,
    STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    COUNT(DISTINCT co.name) FILTER (WHERE co.country_code IS NOT NULL) AS company_count,
    ROW_NUMBER() OVER (PARTITION BY bh.production_year ORDER BY bh.title) AS row_num
FROM 
    MovieHierarchy bh
LEFT JOIN 
    cast_info ci ON bh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON bh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON bh.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    bh.depth <= 3
GROUP BY 
    bh.movie_id, bh.title, bh.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 0
ORDER BY 
    bh.production_year DESC, 
    bh.title;
