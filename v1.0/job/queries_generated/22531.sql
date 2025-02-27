WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR(MAX)) AS path
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || t.title AS VARCHAR(MAX))
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.level < 5
)

SELECT 
    a.person_id,
    a.name,
    COUNT(DISTINCT c.movie_id) AS movies_starred,
    STRING_AGG(DISTINCT CONCAT(DISTINCT mh.path, ' (', mh.production_year, ')'), ', ') AS movie_paths,
    RANK() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS movie_rank,
    MAX(CASE WHEN p.info_type_id = 1 THEN p.info ELSE NULL END) AS birth_date,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.info ILIKE '%Oscar%' AND mi.movie_id IN (SELECT mh.movie_id FROM MovieHierarchy mh WHERE mh.level <= 3)) AS oscar_count
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
LEFT JOIN person_info p ON a.person_id = p.person_id
LEFT JOIN MovieHierarchy mh ON c.movie_id = mh.movie_id
WHERE a.name IS NOT NULL 
    AND a.name NOT LIKE '%Test%' 
    AND c.note IS NULL
    AND (p.info IS NULL OR p.info <> 'Non-relevant info')
GROUP BY a.person_id, a.name
HAVING COUNT(DISTINCT c.movie_id) IS NOT NULL
ORDER BY movies_starred DESC, a.name
LIMIT 100;
