WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        CAST(mt.title AS VARCHAR) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level,
        CONCAT(mh.path, ' -> ', at.title) AS path
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    d.production_year,
    COUNT(*) OVER (PARTITION BY ak.name) AS total_movies,
    STRING_AGG(DISTINCT kw.keyword, ', ') FILTER (WHERE kw.keyword IS NOT NULL) AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    (SELECT 
         movie_id,
         ARRAY_AGG(DISTINCT title) AS titles,
         MAX(production_year) AS production_year
     FROM 
         movie_hierarchy
     GROUP BY movie_id) d ON d.movie_id = at.id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND at.production_year >= 2000
    AND ak.name LIKE 'A%'
GROUP BY 
    ak.name, at.title, d.production_year
ORDER BY 
    total_movies DESC, ak.name, d.production_year DESC
LIMIT 50;

This query performs the following actions:
1. It defines a recursive CTE named `movie_hierarchy` that retrieves movies and links for the hierarchy while calculating the level and path.
2. It joins actors with the titles of movies they participated in, along with their production years.
3. It further aggregates data, counting unique movies associated with each actor and collecting relevant keywords.
4. It applies multiple filtering conditions and sorts the results to generate a list of actors whose names start with 'A', along with the titles of their movies and associated keywords.
5. The final result is limited to the top 50 actors based on the total number of movies they've appeared in.
