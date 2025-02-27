WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Filter for movies produced after 2000

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
    COALESCE(ak.name, 'Unknown') AS Actor_Name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS Keywords,
    COUNT(DISTINCT ci.person_id) AS Total_Cast,
    AVG(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END) AS Avg_Info_Note 
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating' LIMIT 1)
WHERE 
    mh.level <= 3  -- Limit the depth of the hierarchy
GROUP BY 
    mh.movie_id, ak.name, mh.production_year
ORDER BY 
    mh.production_year DESC, 
    Total_Cast DESC
LIMIT 100;  -- Limit the output for performance benchmarking
