WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL 

    SELECT 
        mc.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link mc
    JOIN 
        aka_title mt ON mc.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mc.movie_id = mh.movie_id
)
SELECT 
    ak.person_id,
    ak.name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    SUM(CASE 
            WHEN ak.name IS NULL THEN 1 
            ELSE 0 
        END) AS null_name_count,
    MAX(mh.production_year) AS latest_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ak.name IS NOT NULL
    AND ak.md5sum IS NOT NULL
    AND mh.level <= 2
GROUP BY 
    ak.person_id, ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 3
ORDER BY 
    total_movies DESC,
    latest_production_year DESC
OFFSET 1
FETCH NEXT 5 ROWS ONLY;

In this SQL query:

- A Common Table Expression (CTE) named `movie_hierarchy` is recursively defined to build a movie hierarchy starting from movies produced in or after the year 2000, looking also for linked movies with a maximum depth of 2.
- The main SELECT gathers statistics about persons involved in those movies, including the count of unique movies they were in.
- The inclusion of conditional aggregation allows tracking how many names had NULL values.
- A string aggregation of keywords associated with the films is performed while filtering out persons with NULL names or those lacking an MD5 checksum.
- The results are further filtered using a HAVING clause to ensure that only persons associated with more than three distinct movies are considered, which helps in emphasizing significant contributors in the film industry.
- The final output is ordered by the number of movies and the latest production year, with pagination applied to skip the first result and fetch the next five.
