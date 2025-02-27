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
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COALESCE(ak.name, 'Unknown') AS Actor_Name,
    COUNT(cc.person_id) AS Total_Cast,
    STRING_AGG(DISTINCT k.keyword, ', ') AS Keywords,
    AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE NULL END) * 100 AS Female_Percentage,
    MAX(CASE WHEN m.production_year = 2020 THEN 1 ELSE NULL END) AS Released_2020
FROM 
    MovieHierarchy m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    aka_name ak ON mc.company_id = ak.person_id
LEFT JOIN 
    cast_info cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    movie_keyword kw ON m.movie_id = kw.movie_id
LEFT JOIN 
    keyword k ON kw.keyword_id = k.id
LEFT JOIN 
    name p ON p.imdb_id = cc.person_id
GROUP BY 
    m.movie_id, m.title, m.production_year, ak.name
HAVING 
    COUNT(cc.person_id) > 5
ORDER BY 
    Female_Percentage DESC, Total_Cast DESC;

