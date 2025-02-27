WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
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
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    mh.level AS Hierarchy_Level,
    COALESCE(GROUP_CONCAT(DISTINCT ak.name SEPARATOR ', '), 'No Cast') AS Cast_Names,
    COUNT(DISTINCT mk.keyword) AS Keyword_Count,
    AVG(mp.rating) AS Average_Rating
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    (SELECT movie_id, AVG(rating) AS rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating') GROUP BY movie_id) mp ON mh.movie_id = mp.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    mh.level <= 2
ORDER BY 
    mh.production_year DESC, mh.title;
