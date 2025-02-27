WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COUNT(DISTINCT mc.company_id) AS Total_Companies,
    m.level AS Movie_Level,
    STRING_AGG(DISTINCT ak.name, ', ') AS Actors,
    COUNT(DISTINCT kb.keyword) FILTER (WHERE kb.keyword IS NOT NULL) AS Keyword_Count,
    AVG(COALESCE(pi.info_type_id, 0)) AS Average_Info_Type,
    MAX(ki.kind) AS Movie_Kind
FROM 
    movie_hierarchy m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kb ON mk.keyword_id = kb.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    info_type pi ON mi.info_type_id = pi.id
LEFT JOIN 
    kind_type ki ON m.kind_id = ki.id
GROUP BY 
    m.movie_id, m.title, m.production_year, m.level
ORDER BY 
    m.production_year DESC, Total_Companies DESC;
