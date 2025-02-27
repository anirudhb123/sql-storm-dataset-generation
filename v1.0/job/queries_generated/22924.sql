WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2023
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    m.title AS Main_Movie_Title,
    CAST(COALESCE(NULLIF(AKA.name, ''), 'Unknown Actor') AS text) AS Actor_Name,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS Company_Count,
    SUM(
        CASE 
            WHEN mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Comedy%') THEN 1 
            ELSE 0 
        END
    ) OVER (PARTITION BY m.title) AS Comedy_Count,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS Keywords,
    COUNT(DISTINCT mi.info) FILTER (WHERE mi.info IS NOT NULL) AS Info_Count,
    COUNT(*) FILTER (WHERE c.nr_order < 3) AS Top_Cast_Count
FROM 
    movie_hierarchy m
LEFT JOIN 
    complete_cast c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name AKA ON c.subject_id = AKA.person_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
GROUP BY 
    m.title, AKA.name, mt.production_year
HAVING 
    COUNT(DISTINCT mi.note) > 1
ORDER BY 
    Comedy_Count DESC,
    Company_Count DESC,
    Main_Movie_Title ASC
OFFSET 5 LIMIT 10;
