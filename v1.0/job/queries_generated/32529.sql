WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- Filtering for movies only

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COALESCE(a.name, 'Unknown') AS Actor_Name,
    COUNT(DISTINCT c.id) AS Cast_Count,
    CASE 
        WHEN m.production_year > 2000 THEN 'Modern'
        ELSE 'Classic'
    END AS Era,
    COUNT(DISTINCT kw.keyword) AS Keyword_Count,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COALESCE(a.name, 'Unknown')) AS Row_Num
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    m.level = 0  -- We're only interested in top-level movies
GROUP BY 
    m.movie_id, m.title, m.production_year, a.name
ORDER BY 
    m.production_year DESC, 
    Count(DISTINCT c.id) DESC, 
    m.title;
