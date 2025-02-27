WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    mh.depth AS Depth,
    COALESCE(ki.keyword, 'No Keywords') AS Keywords,
    ARRAY_AGG(DISTINCT cn.name) AS Company_Names,
    COUNT(ci.person_id) AS Cast_Count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    mh.depth < 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth, ki.keyword
HAVING 
    COUNT(ci.person_id) > 5 OR COUNT(DISTINCT cn.id) > 1
ORDER BY 
    mh.production_year DESC, mh.title ASC;
