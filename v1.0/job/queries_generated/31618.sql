WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM aka_title AS m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        mk.linked_movie_id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM movie_link AS mk
    JOIN aka_title AS m ON mk.linked_movie_id = m.id
    JOIN movie_hierarchy AS mh ON mk.movie_id = mh.movie_id
), 

top_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COUNT(cc.id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(cc.id) DESC) AS rank
    FROM movie_hierarchy AS mh
    LEFT JOIN full_cast AS cc ON mh.movie_id = cc.movie_id
    GROUP BY mh.movie_id, mh.movie_title, mh.production_year
)

SELECT 
    t.movie_title,
    t.production_year,
    COALESCE(cc.actor_count, 0) AS actor_count,
    GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS actors,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM top_movies AS t
LEFT JOIN cast_info AS cc ON t.movie_id = cc.movie_id
LEFT JOIN aka_name AS ak ON cc.person_id = ak.person_id
LEFT JOIN movie_keyword AS mk ON t.movie_id = mk.movie_id
WHERE t.rank <= 10
GROUP BY t.movie_id, t.movie_title, t.production_year
ORDER BY t.production_year DESC;
