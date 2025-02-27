WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::INTEGER AS parent_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- considering movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year >= 2000
    -- Filtering for potentially linked movies also from the year 2000 onwards
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    level,
    COUNT(mh.parent_id) AS num_links,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS recent_movie_rank,
    CASE 
        WHEN mt.production_year < 2010 THEN 'Older Movie'
        ELSE 'Recent Movie'
    END AS movie_age_category
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title, mt.production_year, level
HAVING 
    COUNT(mh.parent_id) > 0
ORDER BY 
    actor_name, recent_movie_rank;

This SQL query performs the following tasks:

1. It defines a recursive common table expression (CTE) named `movie_hierarchy` to build a hierarchy of movies that are linked together, starting from the movies produced from the year 2000 onwards. 

2. The main query selects actor names (`ak.name`), corresponding movie titles, production years, and the hierarchy levels of movies.

3. It counts the number of links each movie has in the hierarchy and retrieves keywords associated with each movie.

4. A window function generates a ranking of the most recent movies for each actor.

5. The query categorizes movies into 'Older Movie' or 'Recent Movie' based on their production year.

6. The `HAVING` clause ensures only those actors' movies are returned which have at least one linked movie.

The results are ordered by actor name and their recent movie ranking to give a comprehensive overview of actors' involvement in the film industry relative to linked movies over time.
