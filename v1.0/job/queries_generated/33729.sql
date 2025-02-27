WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT m.id AS movie_id, m.title, m.production_year, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 3  -- Limit the depth of recursion
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT an.name) AS actor_names,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mt.info, '; ') AS movie_info
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info LIKE '%Awards%'
    GROUP BY mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.actor_names, '{}'::text[]) AS actor_names,
    COALESCE(cs.total_actors, 0) AS total_actors,
    COALESCE(mis.movie_info, 'No awards info') AS awards_info,
    COUNT(DISTINCT ml.linked_movie_id) AS related_movies,
    COUNT(DISTINCT CASE WHEN ml.link_type_id IS NULL THEN 1 END) AS orphan_links,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank_within_year
FROM movie_hierarchy mh
LEFT JOIN cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN movie_info_summary mis ON mh.movie_id = mis.movie_id
LEFT JOIN movie_link ml ON mh.movie_id = ml.movie_id
GROUP BY mh.movie_id, mh.title, mh.production_year, cs.actor_names, cs.total_actors, mis.movie_info
ORDER BY mh.production_year DESC, mh.title;
