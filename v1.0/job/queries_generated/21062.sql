WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM aka_title AS mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1 AS level,
        CAST(mh.path || ' -> ' || lt.title AS VARCHAR(255)) AS path
    FROM MovieHierarchy AS mh
    JOIN movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN aka_title AS lt ON ml.linked_movie_id = lt.id
    WHERE lt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COUNT(DISTINCT c.person_id) AS Cast_Count,
    STRING_AGG(DISTINCT a.name, ', ') AS Cast_Names,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN mi.info END) AS Budget,
    SUM(CASE WHEN mk.keyword = 'action' THEN 1 ELSE 0 END) AS Action_Keywords,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS Movie_Rank
FROM 
    MovieHierarchy AS m
LEFT JOIN 
    complete_cast AS cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name AS a ON c.person_id = a.person_id
LEFT JOIN 
    movie_info AS mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword AS mk ON m.movie_id = mk.movie_id
WHERE 
    m.production_year IS NOT NULL
    AND (m.production_year BETWEEN 2000 AND 2023)
    AND (
        CAST(m.production_year AS INTEGER) % 2 = 0  -- Only even years
        OR EXISTS (SELECT 1 FROM movie_keyword WHERE keyword = 'thriller' AND movie_id = m.movie_id)
    )
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.person_id) >= 3
ORDER BY 
    m.production_year DESC, Cast_Count DESC; 
