WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM
        aka_title t
    JOIN
        movie_companies mc ON mc.movie_id = t.id
    JOIN
        company_name cn ON mc.company_id = cn.id
    WHERE
        t.production_year >= 2000
        AND cn.country_code = 'USA'
    
    UNION ALL

    SELECT
        mh.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title t ON ml.linked_movie_id = t.id
)

SELECT
    p.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS total_movies,
    AVG(m.production_year) AS avg_production_year,
    MAX(m.production_year) AS last_movie_year,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    SUM(CASE WHEN m.production_year < 2023 THEN 1 ELSE 0 END) AS older_movies_count
FROM
    cast_info ci
JOIN
    aka_name p ON ci.person_id = p.person_id
JOIN
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN
    movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
WHERE
    p.name IS NOT NULL
    AND ci.nr_order = 1
GROUP BY
    p.name
HAVING
    COUNT(DISTINCT ch.movie_id) > 5
ORDER BY
    total_movies DESC
LIMIT 10;

This SQL query creates a recursive Common Table Expression (CTE) to build a movie hierarchy for movies produced after 2000 and produced in the USA. It then selects the actor's name, counts the number of movies they starred in (with additional calculations such as average and maximum production years), and retrieves a concatenated list of movie titles. The outer query filters out any actors with fewer than 5 movies in the resulting list and orders the results by the total number of movies they starred in, limiting the results to the top 10 actors.
