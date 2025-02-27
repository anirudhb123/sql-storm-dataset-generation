WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mv.title AS Movie_Title,
    mv.production_year AS Production_Year,
    COUNT(c.person_id) AS Cast_Count,
    AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) * 100 AS Female_Cast_Percentage,
    STRING_AGG(DISTINCT co.name, '; ') AS Companies,
    MAX(CASE WHEN ki.keyword = 'Award' THEN 1 ELSE 0 END) AS Has_Award_Keyword,
    ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY mv.title) AS Title_Rank
FROM 
    MovieHierarchy mv
LEFT JOIN 
    cast_info c ON mv.movie_id = c.movie_id
LEFT JOIN 
    name p ON c.person_id = p.id
LEFT JOIN 
    movie_companies mc ON mv.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
GROUP BY 
    mv.movie_id, mv.title, mv.production_year
ORDER BY 
    mv.production_year DESC, COUNT(c.person_id) DESC;
