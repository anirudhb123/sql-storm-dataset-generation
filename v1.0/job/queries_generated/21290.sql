WITH RECURSIVE MoviePaths AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        ARRAY[t.title] AS path, 
        1 AS depth
    FROM 
        aka_title AS t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        m.movie_id, 
        t.title, 
        path || t.title, 
        depth + 1
    FROM 
        MoviePaths AS m
    JOIN 
        movie_link AS ml ON m.movie_id = ml.movie_id
    JOIN 
        title AS t ON ml.linked_movie_id = t.id
    WHERE 
        depth < 5
)

SELECT 
    p.person_id,
    a.name AS actor_name,
    ARRAY_AGG(DISTINCT m.title) AS movie_titles,
    SUM(CASE 
            WHEN pi.info_type_id = 1 THEN 1 
            ELSE 0 
        END) AS award_count,
    ROW_NUMBER() OVER (PARTITION BY p.person_id ORDER BY SUM(pi.info_type_id)) AS rank
FROM 
    person_info AS pi
JOIN 
    cast_info AS ci ON pi.person_id = ci.person_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
LEFT JOIN 
    MoviePaths AS m ON t.id = m.movie_id
WHERE 
    pi.info_type_id IS NOT NULL 
    AND a.name IS NOT NULL
GROUP BY 
    p.person_id, a.name
HAVING 
    COUNT(m.movie_id) > 2 
    AND SUM(CASE WHEN t.production_year IS NULL THEN 1 ELSE 0 END) = 0
ORDER BY 
    rank, 
    actor_name COLLATE "C" ASC NULLS LAST;

This SQL query involves a Common Table Expression (CTE) to create a hierarchy of movies linked together by the 'movie_link' table, allowing for recursive evaluation of links up to five levels deep. It aggregates data for actors, including their name, the titles of movies they have been involved in, and their number of awards from the 'person_info' table, while also handling NULL values and utilizing window functions for ranking the results. The use of the `HAVING` clause introduces some complexity by ensuring only actors tied to more than two movies are included, while also checking that there are no null production years among the selected titles.
