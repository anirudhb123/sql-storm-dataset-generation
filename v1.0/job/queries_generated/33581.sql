WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000  -- Base case: Movies from the year 2000 and beyond

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    WHERE mh.level < 3  -- Limit the recursion to a maximum depth of 3
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(CASE WHEN c.nr_order IS NOT NULL THEN 1 END) AS cast_count,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    AVG(mi.info::NUMERIC) AS average_info -- Assuming the info can be cast to numeric
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN MovieHierarchy mh ON c.movie_id = mh.movie_id
JOIN aka_title mt ON mh.movie_id = mt.id
LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_info mi ON mt.id = mi.movie_id
WHERE a.name IS NOT NULL
    AND mt.production_year IS NOT NULL
    AND (mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Budget', 'Revenue')))
GROUP BY a.name, mt.title, mt.production_year
ORDER BY average_info DESC NULLS LAST
LIMIT 100;
