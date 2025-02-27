WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    a.name AS actor_name,
    COALESCE(COUNT(DISTINCT c.movie_id), 0) AS total_movies,
    COALESCE(MAX(h.level), 0) AS max_link_level,
    STRING_AGG(DISTINCT t.title, ', ') AS all_titles,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    CASE 
        WHEN COUNT(DISTINCT c.movie_id) > 10 THEN 'Prolific'
        WHEN COUNT(DISTINCT c.movie_id) BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Rare'
    END AS actor_activity,
    SUM(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count
FROM aka_name a
LEFT JOIN cast_info c ON a.person_id = c.person_id
LEFT JOIN movie_info mi ON c.movie_id = mi.movie_id 
LEFT JOIN movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_hierarchy h ON c.movie_id = h.movie_id
GROUP BY a.name
ORDER BY total_movies DESC, actor_name
LIMIT 50;
