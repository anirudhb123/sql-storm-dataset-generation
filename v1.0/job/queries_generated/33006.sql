WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        CAST(NULL AS text) AS parent_movie_title,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        p.movie_title AS parent_movie_title,
        level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy p ON m.episode_of_id = p.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.parent_movie_title,
    COUNT(c.id) AS cast_count,
    ARRAY_AGG(DISTINCT a.name) AS actor_names,
    MIN(c.nr_order) AS min_order,
    MAX(c.nr_order) AS max_order,
    CASE 
        WHEN AVG(c.nr_order) IS NULL THEN 'No Cast'
        ELSE ROUND(AVG(c.nr_order), 2)::text
    END AS average_order
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info c ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = c.person_id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.parent_movie_title, mh.production_year
ORDER BY 
    mh.production_year DESC, mh.movie_id;

