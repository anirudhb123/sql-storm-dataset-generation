WITH RECURSIVE MovieHierarchy AS (
    -- Get initial movies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.season_nr,
        mt.episode_nr,
        mt.episode_of_id,
        ARRAY[mt.id] AS path
    FROM title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    -- Recursive part to find linked movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        mh.path || ml.linked_movie_id
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
)

SELECT 
    mk.keyword,
    mh.production_year,
    COUNT(DISTINCT c.id) AS cast_count,
    STRING_AGG(DISTINCT a.name ORDER BY a.name) AS actors,
    AVG(CASE 
            WHEN c.note IS NOT NULL THEN 1 
            ELSE NULL 
        END) AS average_note
FROM MovieHierarchy mh
JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN complete_cast cc ON mh.movie_id = cc.movie_id
JOIN cast_info c ON cc.subject_id = c.person_id
JOIN aka_name a ON c.person_id = a.person_id
WHERE 
    mk.keyword IS NOT NULL 
    AND mh.level <= 2
GROUP BY mk.keyword, mh.production_year
HAVING COUNT(DISTINCT c.id) > 3
ORDER BY mh.production_year DESC, cast_count DESC;
