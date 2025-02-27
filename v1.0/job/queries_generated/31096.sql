WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS depth
    FROM title m
    WHERE m.production_year > 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        mh.depth + 1
    FROM title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

ranked_cast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.depth,
    ARRAY_AGG(DISTINCT rk.actor_name) AS actors,
    mk.keywords,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    AVG(CASE WHEN ci.person_role_id IS NULL THEN 0 ELSE ci.person_role_id END) AS avg_role_id
FROM movie_hierarchy mh
LEFT JOIN ranked_cast rk ON mh.movie_id = rk.movie_id
LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
GROUP BY 
    mh.movie_id, 
    mh.title, 
    mh.depth, 
    mk.keywords
HAVING 
    COUNT(DISTINCT rk.actor_name) > 1 
    AND AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN ci.person_role_id END) > 1
ORDER BY 
    mh.depth DESC, 
    COUNT(DISTINCT rk.actor_name) DESC;
