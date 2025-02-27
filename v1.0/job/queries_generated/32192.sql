WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_movie
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        lt.title,
        lt.production_year,
        mh.movie_id AS parent_movie
    FROM 
        movie_link ml
    JOIN 
        title lt ON ml.linked_movie_id = lt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    mh.title AS parent_movie_title,
    mh.production_year AS parent_movie_year,
    COUNT(DISTINCT ac.movie_id) AS total_movies,
    AVG(mv.production_year) AS average_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_used
FROM 
    aka_name a
JOIN 
    cast_info ac ON a.person_id = ac.person_id
JOIN 
    aka_title at ON ac.movie_id = at.movie_id
LEFT JOIN 
    MovieHierarchy mh ON ac.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
INNER JOIN 
    title mv ON ac.movie_id = mv.id
WHERE 
    a.name IS NOT NULL
    AND at.production_year IS NOT NULL
    AND (at.production_year >= 2000 OR (mh.parent_movie IS NOT NULL AND mh.parent_movie > 0))
GROUP BY 
    a.name, at.title, mh.title, mh.production_year
ORDER BY 
    total_movies DESC, average_year ASC
LIMIT 100;

This SQL query constructs a recursive common table expression (CTE) to build a hierarchy of movies linked to each other starting from movies produced after the year 2000. It aggregates data from several tables, including `aka_name`, `cast_info`, `aka_title`, `movie_keyword`, and `keyword`, to provide insight into the actors, the titles of the movies they've acted in, and any associated parent movies from the hierarchy. It also includes string aggregation for keywords related to those movies, with filtering for non-null fields and ordering by total movies and average production year.
