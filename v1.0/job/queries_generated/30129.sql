WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(c.name, 'Unknown') AS company_name,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(e.name, 'Unknown') AS company_name,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title e ON ml.linked_movie_id = e.id
    WHERE 
        mh.level < 3  -- Limit the depth of recursion for performance
)

SELECT 
    title.title,
    title.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    MAX(CASE 
        WHEN ci.role_id = 1 THEN 'Lead Actor' 
        WHEN ci.role_id = 2 THEN 'Supporting Actor'
        ELSE 'Other' END) AS primary_role,

    STRING_AGG(DISTINCT CONCAT(a.name, ' as ', rt.role), ', ') AS cast_details,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE mc.note IS NULL) AS companies_without_notes,
    
    ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast_count

FROM 
    title
LEFT JOIN 
    cast_info ci ON title.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_companies mc ON title.id = mc.movie_id
WHERE 
    title.production_year >= 2000
GROUP BY 
    title.id
HAVING 
    COUNT(ci.person_id) > 10  -- Only consider movies with a significant cast
ORDER BY 
    title.production_year DESC, rank_by_cast_count;
