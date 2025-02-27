WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mt.linked_movie_id,
        0 AS level
    FROM 
        title t
    LEFT JOIN 
        movie_link mt ON t.id = mt.movie_id
    WHERE 
        mt.link_type_id = 1  -- Assuming link_type_id = 1 specifies a certain type of relationship

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
    WHERE 
        mh.level < 5  -- Limiting to 5 levels deep to avoid excessive recursion
)

SELECT 
    m.title AS Parent_Movie,
    m.production_year AS Production_Year,
    mh.title AS Linked_Movie,
    mh.level AS Link_Level,
    COUNT(DISTINCT ci.person_id) AS Cast_Count,
    STRING_AGG(DISTINCT ak.name, ', ') AS All_Actors,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) END) AS Avg_Info_Length,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS Keywords
FROM 
    MovieHierarchy mh
JOIN 
    title m ON mh.movie_id = m.id
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')  -- Assuming there is an 'info_type' for summary
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
GROUP BY 
    m.id, m.title, m.production_year, mh.level
ORDER BY 
    Production_Year DESC, Link_Level ASC;
