WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(CAST(m.info AS TEXT), 'No Info') AS movie_info,
        lvl
    FROM title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    CROSS JOIN (SELECT 1 AS lvl) AS levels

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(CAST(ti.info AS TEXT), 'No Info') AS movie_info,
        m.lvl + 1
    FROM title t
    JOIN movie_link ml ON t.id = ml.linked_movie_id
    JOIN movie_hierarchy m ON ml.movie_id = m.movie_id
)
SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    mh.movie_info,
    tm.production_year,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY tm.production_year DESC) AS recent_movie_rank,
    COUNT(DISTINCT CASE WHEN mi.info_type_id = 5 THEN mi.info END) AS unique_award_count,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS total_cast_notes,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MIN(CASE WHEN c.nr_order IS NULL THEN 'Missing Order' ELSE CAST(c.nr_order AS TEXT) END) AS first_order
FROM aka_name ak
JOIN cast_info c ON ak.person_id = c.person_id
JOIN movie_companies mc ON c.movie_id = mc.movie_id
JOIN aka_title at ON c.movie_id = at.movie_id
JOIN movie_info mi ON c.movie_id = mi.movie_id
JOIN movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN title t ON m.id = t.id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN keyword k ON mk.keyword_id = k.id
JOIN title tm ON tm.id = t.id
WHERE 
    ak.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
    AND (c.note LIKE 'Starring%' OR c.note IS NULL)
GROUP BY 
    ak.person_id, ak.name, t.title, mh.movie_info, tm.production_year
HAVING 
    COUNT(DISTINCT mi.id) > 1
ORDER BY 
    recent_movie_rank,
    ak.name DESC,
    t.production_year DESC;
