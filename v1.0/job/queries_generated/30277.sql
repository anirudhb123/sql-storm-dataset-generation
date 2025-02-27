WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Filter for movies after 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ch.id) AS character_count,
    AVG(mh.depth) AS avg_movie_depth,
    STRING_AGG(DISTINCT mt.title || ' (' || mt.production_year || ')', ', ') AS movies,
    SUM(CASE 
            WHEN mp.note IS NULL THEN 0
            ELSE 1 
        END) AS non_null_notes
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    char_name ch ON ch.id = ci.role_id
LEFT JOIN 
    movie_info mp ON mp.movie_id = ci.movie_id AND mp.info_type_id = (SELECT id FROM info_type WHERE info = 'note')
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5  -- Only keep actors with more than 5 films
ORDER BY 
    character_count DESC, 
    avg_movie_depth ASC
LIMIT 10;

This SQL query does the following:
- Creates a recursive Common Table Expression (CTE) `MovieHierarchy` to retrieve movies from the `aka_title` table, starting from those produced after the year 2000, including their linked movies.
- It then gathers information on actors, including their names, counts of distinct characters they have played, average movie depth from the `MovieHierarchy`, and a list of movies they've been in.
- The query also retrieves non-null notes from `movie_info` for each movie, using a LEFT JOIN.
- It filters actors based on having acted in more than 5 movies and orders the results for the top 10 actors by character count and average movie depth.
