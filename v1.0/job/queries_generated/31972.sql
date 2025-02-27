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
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 5
)

SELECT 
    co.name AS company_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(CASE 
        WHEN mi.info IS NOT NULL THEN 1 
        ELSE 0 
    END) AS average_info_present,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    MAX(mh.production_year) AS latest_movie_year
FROM 
    movie_companies mc 
JOIN 
    company_name co ON mc.company_id = co.id 
LEFT JOIN 
    complete_cast cc ON mc.movie_id = cc.movie_id
LEFT JOIN 
    movie_info mi ON mc.movie_id = mi.movie_id 
LEFT JOIN 
    movie_keyword mk ON mc.movie_id = mk.movie_id 
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id 
LEFT JOIN 
    MovieHierarchy mh ON mc.movie_id = mh.movie_id
WHERE 
    co.country_code IS NOT NULL 
    AND co.name IS NOT NULL
GROUP BY 
    co.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 3
ORDER BY 
    movie_count DESC, company_name;
