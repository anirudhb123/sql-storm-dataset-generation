WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           1 AS level, CAST(mt.title AS text) AS path
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT m.id AS movie_id, m.title, m.production_year, 
           mh.level + 1 AS level, CAST(mh.path || ' -> ' || m.title AS text)
    FROM movie_link ml
    JOIN title m ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(CASE WHEN a.title IS NOT NULL THEN 1 END) AS total_movies,
    MAX(m.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT mh.path, ', ') AS movie_paths,
    SUM(CASE WHEN ak.md5sum IS NOT NULL THEN 1 ELSE 0 END) AS md5_valid_count
FROM aka_name ak
LEFT JOIN cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN aka_title a ON ci.movie_id = a.id
LEFT JOIN movie_hierarchy mh ON a.id = mh.movie_id
WHERE ak.name IS NOT NULL
GROUP BY ak.name
HAVING COUNT(DISTINCT a.id) > 0
ORDER BY latest_movie_year DESC NULLS LAST
LIMIT 10;

WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_per_year
    FROM aka_title a
    WHERE a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
),
movie_summary AS (
    SELECT 
        rm.production_year,
        COUNT(rm.movie_id) AS movie_count,
        AVG(rm.rank_per_year) AS avg_rank
    FROM ranked_movies rm
    GROUP BY rm.production_year
)

SELECT 
    ms.production_year,
    ms.movie_count,
    COALESCE(ms.avg_rank, 0) AS avg_rank,
    CASE 
        WHEN ms.movie_count > 10 THEN 'Popular Year'
        ELSE 'Less Popular Year'
    END AS popularity
FROM movie_summary ms
ORDER BY ms.production_year DESC;
