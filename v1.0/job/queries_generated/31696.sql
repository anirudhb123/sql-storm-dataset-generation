WITH RECURSIVE MovieHierarchy AS (
    -- Base case: select all movies
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM title t
    WHERE t.production_year >= 2000  -- Consider movies from the year 2000 onward

    UNION ALL

    -- Recursive case: join the movie_link table to find linked movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
)

SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COALESCE(a.name, 'Unknown') AS Actor_Name,
    CAST(COUNT(DISTINCT mk.keyword) AS INTEGER) AS Keyword_Count,
    MAX(mh.level) AS Max_Linked_Level,
    STRING_AGG(DISTINCT it.info, ', ') AS Info_Types,
    AVG(COALESCE(CASE WHEN ci.note IS NOT NULL AND ci.note != '' THEN 1 ELSE NULL END, 0)) AS Actor_Note_Indicators
FROM MovieHierarchy m
LEFT JOIN cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN aka_name a ON ci.person_id = a.person_id
LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN info_type it ON mi.info_type_id = it.id
GROUP BY m.movie_id, m.title, m.production_year, a.name
ORDER BY AVG(COALESCE(CASE WHEN ci.note IS NOT NULL AND ci.note != '' THEN 1 ELSE NULL END, 0)) DESC, m.production_year DESC
LIMIT 50;

-- This query fetches movies from the year 2000 onwards, along with their actors, keywords, and other info types 
-- while exploring linkages through a recursive CTE. It includes various SQL constructs such as outer joins, aggregation, 
-- and conditional logic showcasing performance benchmarking.
