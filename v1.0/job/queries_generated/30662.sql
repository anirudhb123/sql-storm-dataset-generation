WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        m.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id 
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
)
SELECT 
    mv.title AS Movie_Title,
    mv.production_year AS Production_Year,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS Movie_Keywords,
    COUNT(DISTINCT c.person_id) AS Total_Cast,
    AVG(CASE WHEN p.info_type_id = 1 THEN p.info::numeric ELSE NULL END) AS Avg_Rating, -- Assuming info_type_id = 1 represents ratings
    ARRAY_AGG(DISTINCT ca.name) FILTER (WHERE ca.name IS NOT NULL) AS Cast_Names
FROM 
    movie_hierarchy mv
LEFT JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
LEFT JOIN 
    aka_name ca ON c.person_id = ca.person_id
WHERE 
    mv.keyword IS NOT NULL
GROUP BY 
    mv.movie_id, mv.title, mv.production_year
ORDER BY 
    mv.production_year DESC, Total_Cast DESC
LIMIT 100;

This SQL query fetches data for a movie hierarchy between 2000 and 2020, collects associated keywords, counts the total cast, averages ratings from person info, and aggregates cast names. It showcases various SQL concepts including recursive CTEs, outer joins, filtering with aggregates, and CTE structures.
