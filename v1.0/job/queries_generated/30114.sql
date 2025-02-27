WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title linked ON linked.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = m.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(cast_count.count, 0) AS cast_count,
    string_agg(DISTINCT a.name, ', ') AS actors,
    AVG(CASE 
            WHEN pi.info_type_id = 1 THEN CAST(pi.info AS FLOAT)
            ELSE NULL 
        END) AS average_rating,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    CASE WHEN AVG(CASE WHEN pi.info_type_id = 1 THEN CAST(pi.info AS FLOAT) END) IS NULL 
         THEN 'N/A' 
         ELSE 'Rated' 
    END AS rating_status
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    person_info pi ON pi.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, COUNT(*) AS count 
     FROM 
         cast_info 
     GROUP BY 
         movie_id) AS cast_count ON cast_count.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cast_count.count, mh.level
ORDER BY 
    mh.production_year DESC, mh.level ASC, mh.title;

This query accomplishes the following:

1. Defines a recursive Common Table Expression (CTE) `movie_hierarchy` that generates a hierarchy of movies produced between 2000 and 2020.
2. Joins multiple tables to gather relevant information about each movie, including details about its cast, associated keywords, and ratings from the `person_info` table.
3. Uses `LEFT JOIN` to ensure that all movies are included, even if they do not have a cast or ratings.
4. Aggregates information such as the count of actors and distinct keywords related to each movie.
5. Computes the average rating and provides logic to handle NULL values in ratings.
6. Implements conditional logic through the `CASE` statement to create a new column `rating_status` that reflects whether or not a movie has a rating.
7. Orders the final results by production year, level of hierarchy, and movie title for better readability.
