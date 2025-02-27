WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000 
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        mh.level + 1
    FROM 
        movie_link ml 
    JOIN 
        title m ON ml.linked_movie_id = m.imdb_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
filtered_cast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS with_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
avg_movie_info AS (
    SELECT 
        mi.movie_id,
        AVG(LENGTH(mi.info)) AS avg_info_length
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        f.total_actors,
        f.with_order,
        COALESCE(a.avg_info_length, 0) AS avg_info_length
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        filtered_cast f ON mh.movie_id = f.movie_id
    LEFT JOIN 
        avg_movie_info a ON mh.movie_id = a.movie_id
)
SELECT 
    tm.title,
    tm.total_actors,
    tm.with_order,
    tm.avg_info_length,
    CASE 
        WHEN tm.total_actors IS NULL THEN 'No Actors' 
        ELSE 'Actors Present' 
    END AS actor_status
FROM 
    top_movies tm 
WHERE 
    (tm.total_actors > 5 OR tm.avg_info_length > 100)
ORDER BY 
    tm.avg_info_length DESC, 
    tm.total_actors DESC
LIMIT 10;