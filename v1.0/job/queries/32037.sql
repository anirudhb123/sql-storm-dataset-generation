WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        at.title AS movie_title,
        1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Sequel')

    UNION ALL

    SELECT 
        mh.movie_id,
        ml.linked_movie_id,
        at.title AS movie_title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
)
SELECT 
    a.title AS Original_Movie,
    mh.movie_title AS Linked_Movie,
    mh.level AS Link_Level,
    COUNT(DISTINCT ci.person_id) AS Total_Cast,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS Avg_Cast_Order,
    STRING_AGG(DISTINCT an.name, ', ') AS Cast_Names
FROM 
    aka_title a
LEFT JOIN 
    MovieHierarchy mh ON a.id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = a.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
WHERE 
    a.production_year >= 2000
    AND (mh.level IS NULL OR mh.level <= 2)  
GROUP BY 
    a.title, mh.movie_title, mh.level
ORDER BY 
    a.title, mh.level;