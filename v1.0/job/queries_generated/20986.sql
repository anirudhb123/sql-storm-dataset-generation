WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        m.id AS root_movie_id
    FROM title m
    WHERE m.production_year >= 2000  -- considering movies from the year 2000 onwards
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        level + 1,
        mh.root_movie_id
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    t.title AS movie_title,
    mh.level,
    COUNT(DISTINCT c.person_id) AS unique_cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS akas,
    MAX(CASE WHEN ci.note IS NOT NULL THEN 'Notes present' ELSE 'No notes' END) AS notes_status
FROM movie_hierarchy mh
LEFT JOIN complete_cast c ON mh.movie_id = c.movie_id
LEFT JOIN aka_title ak ON mh.movie_id = ak.movie_id
LEFT JOIN cast_info ci ON c.person_id = ci.person_id
LEFT JOIN title t ON mh.movie_id = t.id
WHERE mh.level < 3  -- limiting the hierarchy depth
GROUP BY mh.movie_id, t.title, mh.level
HAVING COUNT(DISTINCT c.person_id) > 0
ORDER BY mh.level, unique_cast_count DESC
LIMIT 50;
