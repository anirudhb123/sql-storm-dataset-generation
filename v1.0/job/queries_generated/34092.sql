WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM title m
    WHERE m.kind_id = 1  -- Assuming kind_id '1' denotes 'movie'
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM title m
    JOIN movie_link ml ON m.id = ml.movie_id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
),
actor_performance AS (
    SELECT 
        a.id AS actor_id,
        ka.name AS actor_name,
        COUNT(ci.movie_id) AS total_movies,
        AVG(TIMESTAMPDIFF(YEAR, t.production_year, CURDATE())) AS avg_movie_age
    FROM 
        cast_info ci
    JOIN aka_name ka ON ci.person_id = ka.person_id
    JOIN title t ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY a.id, ka.name
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.id) AS actor_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
    ORDER BY actor_count DESC
    LIMIT 10
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    COALESCE(a.actor_count, 0) AS number_of_actors,
    COALESCE(k.keywords, 'None') AS keywords,
    a.actor_id,
    a.actor_name,
    a.total_movies,
    a.avg_movie_age
FROM 
    top_movies t
LEFT JOIN actor_performance a ON t.movie_id = a.actor_id
LEFT JOIN movie_keywords k ON t.movie_id = k.movie_id
ORDER BY t.production_year DESC, number_of_actors DESC;
