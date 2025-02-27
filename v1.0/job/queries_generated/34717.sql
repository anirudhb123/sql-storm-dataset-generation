WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
top_movies AS (
    SELECT 
        movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(m.production_year) AS avg_year,
        MAX(m.production_year) AS latest_year
    FROM 
        complete_cast cc
    JOIN 
        movie_hierarchy mh ON cc.movie_id = mh.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = mh.movie_id
    GROUP BY 
        movie_id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
actor_details AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        movie_hierarchy t ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.name, t.title, t.production_year
)
SELECT 
    ad.actor_name,
    ad.movie_title,
    ad.production_year,
    th.actor_count,
    th.avg_year,
    th.latest_year,
    NULLIF(ad.keyword_count, 0) AS keyword_count
FROM 
    actor_details ad
JOIN 
    top_movies th ON ad.movie_title = th.movie_id
ORDER BY 
    th.actor_count DESC, 
    ad.movie_title;
