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
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM 
        movie_link ml 
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    t.title AS Movie_Title,
    COUNT(DISTINCT ci.person_id) AS Total_Cast,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS Cast_With_Notes,
    MAX(mf.info) AS Movie_Description,
    STRING_AGG(DISTINCT ak.name || ' (' || ak.imdb_index || ')', ', ') AS Aliases,
    STRING_AGG(DISTINCT cn.name, ', ') AS Company_Names,
    COUNT(DISTINCT mk.keyword) AS Total_Keywords,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS Rank_By_Cast_Size
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mf ON mh.movie_id = mf.movie_id AND mf.info_type_id = (SELECT id FROM info_type WHERE info = 'Description' LIMIT 1)
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
WHERE 
    mh.level = 1
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    mh.production_year DESC, Total_Cast DESC;
