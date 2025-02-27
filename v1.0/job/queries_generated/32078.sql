WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(cn.name, 'Unknown Company') AS production_company,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast_count,
    MAX(CASE WHEN m.production_year = 2023 THEN 'New Release' ELSE 'Older Release' END) AS release_status
FROM 
    MovieHierarchy m
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = m.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
WHERE 
    m.production_year IS NOT NULL
GROUP BY 
    m.movie_id, m.title, m.production_year, cn.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    rank_by_cast_count;
