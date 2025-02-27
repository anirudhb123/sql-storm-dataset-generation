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
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COUNT(DISTINCT cast.id) AS cast_count,
    ARRAY_AGG(DISTINCT c.name ORDER BY c.name) AS cast_names,
    COALESCE(ci.kind, 'N/A') AS company_kind,
    AVG(mv.info::decimal) AS avg_movie_info,
    MAX(CASE 
        WHEN mv.note IS NOT NULL THEN mv.note 
        ELSE 'No Note' 
    END) AS note_status
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info cast ON cast.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_type ci ON mc.company_type_id = ci.id
LEFT JOIN 
    movie_info mv ON mv.movie_id = m.movie_id
WHERE 
    m.production_year >= 2000
GROUP BY 
    m.movie_id, m.title, m.production_year, ci.kind
HAVING 
    CAST(COUNT(DISTINCT cast.id) AS integer) > 0 
ORDER BY 
    m.production_year DESC,
    cast_count DESC;

This query utilizes a Common Table Expression (CTE) to recursively build a hierarchy of movies linked together, joining those results with various attributes related to casting and movie companies. It aggregates cast members, calculates averages from movie info data, and handles NULLs elegantly through COALESCE to ensure robustness. The overall structure makes it suitable for performance benchmarking on larger datasets.
