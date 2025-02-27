WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.kind_id,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000 -- Start with movies from 2000 onwards
    
    UNION ALL
    
    SELECT 
        t2.id,
        t2.title,
        t2.kind_id,
        t2.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title t2 ON ml.linked_movie_id = t2.id
)

SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    COUNT(DISTINCT ci.person_id) AS Total_Cast,
    STRING_AGG(DISTINCT a.name, ', ') AS Cast_Names,
    AVG(p.info::numeric) AS Avg_Rating,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS Keywords,
    CASE 
        WHEN COUNT(DISTINCT ci.person_id) > 10 THEN 'Ensemble Cast'
        ELSE 'Small Cast'
    END AS Cast_Size_Type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id AND it.info = 'rating'
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    mh.level <= 3 -- Limit depth of hierarchy traversed
GROUP BY 
    mh.title, mh.production_year
HAVING 
    AVG(p.info::numeric) IS NOT NULL -- Only include movies with a rating
ORDER BY 
    AVG(p.info::numeric) DESC, 
    Total_Cast DESC;
