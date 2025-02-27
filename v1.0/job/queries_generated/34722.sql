WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
most_frequent_cast AS (
    SELECT 
        ci.person_id,
        COUNT(*) AS movie_count
    FROM cast_info ci
    JOIN movie_hierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY ci.person_id
    HAVING COUNT(*) > (
        SELECT AVG(movie_count)
        FROM (
            SELECT COUNT(*) AS movie_count
            FROM cast_info
            GROUP BY person_id
        ) AS subquery
    )
),
movie_keyword_data AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword LIKE '%action%'
),
final_output AS (
    SELECT 
        m.movie_title,
        m.production_year,
        ca.name AS actor_name,
        COUNT(DISTINCT mk.keyword) AS action_keywords
    FROM movie_hierarchy m
    JOIN cast_info ci ON m.movie_id = ci.movie_id
    JOIN aka_name ca ON ci.person_id = ca.person_id
    JOIN most_frequent_cast fc ON ci.person_id = fc.person_id
    LEFT JOIN movie_keyword_data mk ON m.movie_id = mk.movie_id
    GROUP BY m.movie_title, m.production_year, ca.name
)
SELECT 
    fo.movie_title,
    fo.production_year,
    fo.actor_name,
    COALESCE(fo.action_keywords, 0) AS action_keywords,
    RANK() OVER (PARTITION BY fo.production_year ORDER BY fo.action_keywords DESC) AS keyword_rank
FROM final_output fo
ORDER BY fo.production_year, keyword_rank
LIMIT 10;
