WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        1 AS level,
        COALESCE(m2.title, 'N/A') AS linked_title
    FROM 
        aka_title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    LEFT JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id,
        m.title,
        mh.level + 1,
        COALESCE(m2.title, 'N/A') AS linked_title
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        m.production_year >= 2000
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.linked_title,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.level DESC) AS rank_level
    FROM 
        movie_hierarchy mh
),
actor_info AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
),
final_results AS (
    SELECT 
        rm.movie_title,
        rm.linked_title,
        ai.actor_name,
        ai.movie_count,
        ai.avg_order
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_info ai ON ai.movie_count > 5
    WHERE 
        rm.rank_level = 1
)
SELECT 
    movie_title, 
    linked_title, 
    actor_name, 
    movie_count, 
    COALESCE(avg_order, 'No Data') AS avg_order
FROM 
    final_results
ORDER BY 
    movie_title, actor_name;
