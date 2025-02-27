WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM title m
    WHERE m.kind_id = 1 -- Assuming '1' represents the main movie kind

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    t.title AS Movie_Title,
    t.production_year AS Production_Year,
    COALESCE(aka.name, 'Unknown') AS Alternate_Name,
    COUNT(ci.person_id) AS Cast_Count,
    STRING_AGG(DISTINCT cn.name, ', ') AS Company_Names,
    SUM(mi.info = 'Awards' AND mi.note IS NOT NULL) AS Awards_Count,
    COUNT(DISTINCT CASE 
        WHEN kw.keyword IS NOT NULL THEN kw.keyword END
    ) AS Keywords_Count,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS Ranking_Year
FROM title t
LEFT JOIN aka_title aka ON aka.movie_id = t.id
LEFT JOIN cast_info ci ON ci.movie_id = t.id
LEFT JOIN movie_companies mc ON mc.movie_id = t.id
LEFT JOIN company_name cn ON cn.id = mc.company_id
LEFT JOIN movie_info mi ON mi.movie_id = t.id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN keyword kw ON kw.id = mk.keyword_id
JOIN MovieHierarchy mh ON mh.movie_id = t.id
GROUP BY 
    t.id, t.title, t.production_year, aka.name
HAVING COUNT(ci.person_id) > 2
ORDER BY Production_Year DESC, Cast_Count DESC;
