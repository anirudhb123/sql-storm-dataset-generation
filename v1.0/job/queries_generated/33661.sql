WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        1 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.hierarchy_level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ah.name AS actor_name,
    mt.title AS movie_title,
    mh.hierarchy_level,
    COUNT(DISTINCT a.movie_id) AS total_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE WHEN cast_info.nr_order IS NOT NULL THEN cast_info.nr_order END) AS avg_order,
    COUNT(DISTINCT c.id) FILTER (WHERE c.kind IS NOT NULL) AS valid_companies,
    MAX(COALESCE(m.production_year, 'Unknown')) AS latest_movie_year
FROM 
    aka_name ah
JOIN 
    cast_info c ON ah.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title mt ON c.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies m ON m.movie_id = mt.movie_id
LEFT JOIN 
    company_name cp ON m.company_id = cp.id
LEFT JOIN 
    comp_cast_type cc ON c.person_role_id = cc.id
WHERE 
    c.note IS NULL
GROUP BY 
    ah.name, mt.title, mh.hierarchy_level
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC, actor_name;

