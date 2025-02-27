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
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id 
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieInfo AS (
    SELECT 
        ma.id AS movie_id,
        ma.title,
        ma.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        MAX(mo.info) AS latest_info
    FROM 
        aka_title ma
    LEFT JOIN 
        movie_keyword mk ON ma.id = mk.movie_id
    LEFT JOIN 
        movie_info mo ON ma.id = mo.movie_id
    GROUP BY 
        ma.id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.keyword_count, 0) AS keyword_count,
    COALESCE(m.latest_info, 'N/A') AS latest_info,
    ARRAY_AGG(DISTINCT ka.name) AS actors,
    ARRAY_AGG(DISTINCT co.name) AS companies
FROM 
    MovieInfo m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name ka ON c.person_id = ka.person_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    m.production_year IS NOT NULL 
    AND m.keyword_count > 0
GROUP BY 
    m.movie_id
HAVING 
    COUNT(DISTINCT c.person_id) > 1
ORDER BY 
    m.production_year DESC
LIMIT 10;

-- Query to benchmark performance with focus on join, aggregation and filtering operations.
