WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = m.id) AS total_actors,
        1 AS level
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = m.id) AS total_actors,
        h.level + 1
    FROM title m
    INNER JOIN movie_hierarchy h ON m.id = h.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.total_actors,
    coalesce(a.name, 'Unknown') AS actor_name,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(mk.movie_id) AS keyword_count,
    RANK() OVER (PARTITION BY mh.total_actors ORDER BY mh.production_year DESC) AS rank_in_year
FROM movie_hierarchy mh
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN aka_name a ON cc.person_id = a.person_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE mh.total_actors > 5
GROUP BY mh.movie_id, mh.title, mh.production_year, a.name
HAVING COUNT(DISTINCT k.keyword) > 2
ORDER BY mh.production_year DESC, mh.total_actors DESC;
