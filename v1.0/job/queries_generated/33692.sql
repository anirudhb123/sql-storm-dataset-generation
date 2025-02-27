WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.imdb_index,
        1 AS level
    FROM 
        aka_title m 
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m2.id AS movie_id,
        m2.title AS movie_title,
        m2.production_year,
        m2.imdb_index,
        mh.level + 1 AS level
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id 
    WHERE 
        mh.level < 5
),
cast_and_movies AS (
    SELECT 
        c.person_id, 
        c.movie_id,
        c.nr_order,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_position
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COUNT(DISTINCT cam.person_id) AS total_actors,
        STRING_AGG(DISTINCT ca.actor_name, ', ') AS actor_list
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_and_movies cam ON mh.movie_id = cam.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year
),
filtered_movies AS (
    SELECT 
        md.*,
        CASE 
            WHEN total_actors IS NULL THEN 'No Cast'
            WHEN total_actors <= 5 THEN 'Few Actors'
            ELSE 'Many Actors'
        END AS actor_category
    FROM 
        movie_details md
    WHERE 
        md.production_year >= 2010
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    fm.total_actors,
    fm.actor_category,
    fm.actor_list
FROM 
    filtered_movies fm
ORDER BY 
    fm.production_year DESC, fm.total_actors DESC;
