WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Starting point (movies only)
    
    UNION ALL
    
    SELECT 
        mv.linked_movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link mv
    JOIN 
        aka_title m ON mv.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mv.movie_id = mh.movie_id 
)

SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    mh.level AS Hierarchy_Level,
    COALESCE(cast_names.names, 'No Cast Info') AS Cast_Names,
    COUNT(DISTINCT mk.keyword_id) AS Keyword_Count,
    AVG(mi.info) AS Average_Info,
    COUNT(DISTINCT mc.company_id) AS Production_Companies
FROM 
    MovieHierarchy mh
LEFT JOIN 
    (SELECT 
         c.movie_id, 
         STRING_AGG(a.name, ', ') AS names
     FROM 
         cast_info c
     JOIN 
         aka_name a ON c.person_id = a.person_id
     GROUP BY 
         c.movie_id) AS cast_names ON mh.movie_id = cast_names.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, cast_names.names
HAVING 
    AVG(mi.info) IS NOT NULL
ORDER BY 
    mh.production_year DESC, 
    Keyword_Count DESC 
LIMIT 50;
