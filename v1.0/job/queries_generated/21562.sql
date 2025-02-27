WITH RECURSIVE movie_hierarchy AS (
    SELECT DISTINCT mt.id AS movie_id, mt.title, mt.production_year,
           CAST(NULL AS VARCHAR(255)) AS parent_title,
           0 AS hierarchy_level
    FROM aka_title mt
    
    UNION ALL

    SELECT DISTINCT ml.linked_movie_id, lt.title, lt.production_year,
           mh.title AS parent_title,
           mh.hierarchy_level + 1
    FROM movie_link ml
    JOIN title lt ON ml.linked_movie_id = lt.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

, ranked_cast AS (
    SELECT ci.movie_id, 
           a.name AS actor_name, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.n_order) AS role_order
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
)

, movie_details AS (
    SELECT mh.movie_id, 
           mh.title, 
           mh.production_year, 
           COUNT(rc.actor_name) AS actor_count,
           AVG(mk.count) AS average_keywords,
           MAX(mk.count) AS max_keywords
    FROM movie_hierarchy mh
    LEFT JOIN ranked_cast rc ON mh.movie_id = rc.movie_id
    LEFT JOIN (
        SELECT movie_id, COUNT(*) AS count
        FROM movie_keyword
        GROUP BY movie_id
    ) mk ON mh.movie_id = mk.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
)

SELECT
    md.title,
    md.production_year,
    md.actor_count,
    md.average_keywords,
    md.max_keywords,
    COALESCE(NULLIF(md.average_keywords, 0), 'N/A') AS safe_average_keywords,
    CASE 
        WHEN md.actor_count > 10 THEN 'Blockbuster'
        WHEN md.actor_count BETWEEN 1 AND 10 THEN 'Indie'
        ELSE 'Unknown'
    END AS movie_category,
    CONCAT('Title: ', md.title, ', Year: ', md.production_year, 
           ', Actors: ', md.actor_count) AS summary
FROM movie_details md
WHERE md.production_year IS NOT NULL
ORDER BY md.production_year DESC, md.actor_count DESC
LIMIT 50;
