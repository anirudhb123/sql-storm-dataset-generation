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
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    kh.keyword AS Keyword,
    ARRAY_AGG(DISTINCT an.name) AS Alternate_Names,
    COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.note IS NULL) as Cast_Without_Note,
    MAX(mo.info) AS Most_Recent_Info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kh ON kh.id = mk.keyword_id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name an ON an.person_id = ci.person_id
LEFT JOIN 
    movie_info mo ON mo.movie_id = mh.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mh.title, mh.production_year, kh.keyword
ORDER BY 
    mh.production_year DESC, Movie_Title;
