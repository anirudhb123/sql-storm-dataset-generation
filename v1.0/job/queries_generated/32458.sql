WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level,
        m.id AS root_movie_id
    FROM title m
    WHERE m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        e.production_year,
        mh.level + 1,
        mh.root_movie_id
    FROM title e
    JOIN movie_link ml ON e.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    t.title AS original_movie,
    t.production_year,
    a.name AS actor_name,
    COUNT(DISTINCT c.person_id) AS number_of_actors,
    AVG(c.nr_order) AS average_role_order,
    MIN(c.nr_order) AS earliest_role_order,
    MAX(c.nr_order) AS latest_role_order,
    COALESCE(k.keyword, 'No Keywords') AS movie_keyword,
    COUNT(DISTINCT ci.company_id) AS affiliated_companies
FROM title t
LEFT JOIN cast_info c ON t.id = c.movie_id
LEFT JOIN aka_name a ON a.person_id = c.person_id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_companies ci ON t.id = ci.movie_id
LEFT JOIN movie_hierarchy mh ON t.id = mh.movie_id
WHERE t.production_year >= 2000
AND (k.keyword IS NOT NULL OR k.keyword IS NULL)
GROUP BY t.title, t.production_year, a.name, k.keyword
ORDER BY t.production_year DESC, number_of_actors DESC, original_movie;
