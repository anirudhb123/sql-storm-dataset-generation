WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.movie_id,
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
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        title m ON ml.movie_id = m.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    COUNT(DISTINCT ci.person_id) AS Cast_Count,
    STRING_AGG(DISTINCT ak.name, ', ') AS Cast_Names,
    AVG(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) ELSE 0 END) AS Avg_Info_Length,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS Null_Notes_Count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    mh.level <= 2 AND -- Limiting hierarchy depth
    mh.production_year > 2000 -- Filtering for modern productions 
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 3 -- At least 4 unique cast members
ORDER BY 
    Avg_Info_Length DESC, 
    Cast_Count DESC
LIMIT 10;

-- Additional information
-- This query creates a recursive CTE to explore the hierarchy of linked movies,
-- aggregates cast information, calculates average lengths of additional info per person, 
-- and counts nulls in notes, all while applying constraints and groupings based on movie characteristics.
