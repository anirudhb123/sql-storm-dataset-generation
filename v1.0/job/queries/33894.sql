
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level,
        t.title AS full_path
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        mh.full_path || ' -> ' || t.title AS full_path
    FROM 
        aka_title t
        JOIN movie_hierarchy mh ON t.episode_of_id = mh.movie_id
)

SELECT 
    CTE.movie_id,
    CTE.title,
    CTE.production_year,
    CTE.level,
    CTE.full_path,
    COUNT(DISTINCT c.person_id) AS actor_count,
    STRING_AGG(DISTINCT n.name, ', ') AS actor_names,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Runtime') THEN mi.info END) AS runtime,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre') THEN mi.info END) AS genre
FROM 
    movie_hierarchy CTE
    LEFT JOIN complete_cast cc ON CTE.movie_id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN aka_name n ON c.person_id = n.person_id
    LEFT JOIN movie_info mi ON CTE.movie_id = mi.movie_id
WHERE 
    CTE.production_year >= 2000
GROUP BY 
    CTE.movie_id, CTE.title, CTE.production_year, CTE.level, CTE.full_path
ORDER BY 
    CTE.production_year DESC,
    actor_count DESC
LIMIT 100;
