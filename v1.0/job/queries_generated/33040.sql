WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(mt2.title, 'N/A') AS parent_movie,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        aka_title mt2 ON mt.episode_of_id = mt2.id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        c.movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(mt2.title, 'N/A') AS parent_movie,
        mh.level + 1
    FROM 
        complete_cast c
    JOIN 
        movie_hierarchy mh ON c.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON c.movie_id = mt.id
    LEFT JOIN 
        aka_title mt2 ON mt.episode_of_id = mt2.id
)
SELECT 
    mh.movie_id, 
    mh.movie_title, 
    mh.production_year, 
    mh.parent_movie,
    LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
    COUNT(DISTINCT ci.person_role_id) AS role_count,
    AVG(CASE WHEN mt.production_year IS NOT NULL THEN 2023 - mt.production_year END) AS avg_age_of_movies
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    mh.production_year IS NOT NULL 
    AND mh.production_year >= 2000 
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.parent_movie
HAVING 
    COUNT(DISTINCT ci.person_role_id) > 1
ORDER BY 
    avg_age_of_movies DESC
LIMIT 10;
This SQL query utilizes a recursive common table expression (CTE) to map a hierarchy of movies and their parent episodes while also aggregating relevant data such as actor names, role counts, and average age of the movies. It involves left joins, string aggregation, and group-by functionality to provide an insightful result for performance benchmarking in a movie database context.
