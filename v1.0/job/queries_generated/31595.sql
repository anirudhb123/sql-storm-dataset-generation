WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        0 AS level,
        mt.id AS movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Start with movies produced after 2000

    UNION ALL

    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        mh.level + 1,
        mt.id AS movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- Limit hierarchy depth to 3 levels
)
SELECT 
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    CASE 
        WHEN COUNT(DISTINCT ak.name) = 0 THEN 'No Actors'
        ELSE ''
    END AS actor_notes,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.movie_title) AS row_num
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    mh.production_year DESC, 
    mh.movie_title;
This SQL query creates a recursive Common Table Expression (CTE) to build a movie hierarchy based on linked movies, while filtering for movies produced after 2000. It then gathers counts of distinct actors per movie, concatenates their names, and adds an additional note in case there are no actors associated with a movie. Finally, it employs a window function to assign row numbers grouped by the production year.
