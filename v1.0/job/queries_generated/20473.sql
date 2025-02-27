WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON a.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
), actors AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        c.nr_order,
        ROW_NUMBER() OVER(PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        c.nr_order IS NOT NULL
), detailed_movies AS (
    SELECT 
        mh.*,
        COALESCE(ARRAY_AGG(DISTINCT a.actor_name) FILTER (WHERE a.actor_rank IS NOT NULL), '{}') AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        actors a ON a.movie_id = mh.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mh.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mh.movie_id
)
SELECT 
    dm.title,
    dm.production_year,
    dm.level,
    dm.actor_names,
    dm.keyword_count,
    CASE
        WHEN dm.level > 3 THEN 'Epic'
        WHEN dm.keyword_count > 5 THEN 'Rich in Keywords'
        ELSE 'Standard'
    END AS movie_category
FROM 
    detailed_movies dm
WHERE 
    dm.actor_names IS NOT NULL
    AND dm.level IS NOT NULL
ORDER BY 
    dm.production_year DESC, 
    dm.level,
    movie_category;
