WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        1 AS level,
        NULL AS parent_movie_id
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        level + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title t ON t.id = ml.movie_id
    WHERE 
        mh.parent_movie_id IS NULL  -- Only include direct links
)

SELECT 
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors_names,
    SUM(CASE WHEN t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%drama%') THEN 1 ELSE 0 END) AS drama_count,
    AVG(COALESCE(COALESCE(pi.info, '0')::numeric, 0)) FILTER (WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) AS average_rating
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id 
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id 
LEFT JOIN 
    title t ON mh.movie_id = t.id 
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id 
LEFT JOIN 
    person_info pi ON pi.person_id = c.person_id 
GROUP BY 
    mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 10 
ORDER BY 
    average_rating DESC NULLS LAST;

This query performs the following actions:

- It defines a recursive Common Table Expression (CTE) named `movie_hierarchy` to find relationships between movies and their sequels or related films.
- It selects movie titles and their production years.
- It counts the number of distinct cast members for each movie.
- It aggregates the names of actors into a comma-separated string.
- It counts the number of movies classified as drama using correlated subqueries.
- It calculates the average rating, while handling NULL values using `COALESCE`.
- It uses a `HAVING` clause to filter results, enabling only those movies with more than 10 cast members.
- Finally, it orders the results by average rating, placing the movies without ratings last.
