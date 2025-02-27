WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2020
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        gt.title AS movie_title,
        gt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title gt ON ml.linked_movie_id = gt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ak.name,
    ak.person_id,
    mh.movie_title,
    mh.production_year,
    COUNT(ci.id) AS cast_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mh.level DESC) AS rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND mh.level <= 2
GROUP BY 
    ak.name, ak.person_id, mh.movie_title, mh.production_year
HAVING 
    AVG(COALESCE(NULLIF(ci.nr_order, 0), 1)) > 2
ORDER BY 
    rank ASC, mh.production_year DESC;

-- Perform a full outer join on movie_info to include any additional details about the movies
LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mi.info_type_id IS NULL OR (mi.info_type_id = (SELECT id FROM info_type WHERE info = 'IMDb Rating'))
ORDER BY 
    mh.production_year DESC;

In this SQL query:

1. A recursive Common Table Expression (CTE) `movie_hierarchy` is used to build a hierarchy of movies released in 2020 and their linked sequels or prequels.
2. The main query selects actor names, production year, and a count of their cast roles for movies within the created hierarchy.
3. It utilizes `STRING_AGG` to display associated keywords for the movies.
4. A `ROW_NUMBER()` window function is used to rank the actors based on their movie levels.
5. The `HAVING` clause filters actors with an average role order greater than 2, skipping direct roles.
6. It performs outer joins to incorporate additional movie information, ensuring completeness even when movie information may not exist.
7. Coalesce and NULL logic are used to manage potential NULL values gracefully.

Overall, this query effectively combines multiple SQL constructs to create a complex analysis of movie data alongside actor contributions while catering to performance benchmarking needs.
