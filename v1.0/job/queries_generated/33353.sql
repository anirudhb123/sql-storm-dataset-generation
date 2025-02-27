WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.production_year >= 2000
), 
cast_and_info AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        ci.movie_id, a.name
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(MAX(cai.actor_rank), 0) AS max_actor_rank,
        COUNT(cai.actor_name) AS total_actors
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_and_info cai ON mh.movie_id = cai.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    fm.title,
    fm.production_year,
    fm.max_actor_rank,
    fm.total_actors,
    CASE 
        WHEN fm.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(fm.production_year AS TEXT)
    END AS production_year_text,
    ARRAY_AGG(DISTINCT actor_name ORDER BY actor_name) AS actors_list
FROM 
    filtered_movies fm
LEFT JOIN 
    cast_and_info cai ON fm.movie_id = cai.movie_id
GROUP BY 
    fm.title, fm.production_year, fm.max_actor_rank, fm.total_actors
HAVING 
    fm.total_actors > 0
ORDER BY 
    fm.production_year DESC, fm.total_actors DESC;
