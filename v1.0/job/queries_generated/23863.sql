WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        CONCAT(h.title, ' -> ', m.title) AS title,
        h.depth + 1
    FROM
        MovieHierarchy h
    JOIN
        aka_title m ON m.episode_of_id = h.movie_id
    WHERE
        h.depth < 5
)

SELECT
    mv.title AS movie_title,
    COALESCE(an.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mct.kind) AS company_type_count,
    SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    ROW_NUMBER() OVER (PARTITION BY mv.title ORDER BY COUNT(DISTINCT an.name) DESC) AS actor_rank,
    CASE 
        WHEN (mv.production_year IS NULL OR mv.production_year < 2000) THEN 'Pre-2000 Film'
        WHEN mv.production_year BETWEEN 2000 AND 2010 THEN 'Early 2000s Film'
        ELSE 'Recent Film'
    END AS film_era
FROM
    MovieHierarchy mv
LEFT JOIN
    cast_info ci ON ci.movie_id = mv.movie_id
LEFT JOIN
    aka_name an ON an.person_id = ci.person_id
LEFT JOIN
    movie_companies mc ON mc.movie_id = mv.movie_id
LEFT JOIN
    company_type mct ON mct.id = mc.company_type_id
LEFT JOIN
    movie_info mi ON mi.movie_id = mv.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%box office%')
GROUP BY
    mv.movie_id, mv.title, an.name
HAVING
    COUNT(DISTINCT an.name) > 2
ORDER BY
    actor_rank DESC,
    mv.title
LIMIT 50;

-- Additionally, selecting Related Titles
SELECT
    m1.title AS original_title,
    m2.title AS related_title
FROM
    aka_title m1
JOIN
    movie_link ml ON ml.movie_id = m1.id
JOIN
    aka_title m2 ON m2.id = ml.linked_movie_id
WHERE
    m1.production_year between 2000 AND 2020
    AND ml.link_type_id IN (SELECT id FROM link_type WHERE link LIKE '%prequel%')
ORDER BY
    m1.title, m2.title;

This SQL query performs several complex operations using CTE (Common Table Expressions), joins, window functions, and conditional logic.

1. It constructs a recursive CTE `MovieHierarchy` that retrieves titles from `aka_title` for movies in a hierarchy up to 5 levels, where the starting point is movies produced in the year 2000 or later.
2. It joins several tables to retrieve data about movies, actors, company types associated with movies, and relevant information type counts, while aggregating and ranking the results by actor participation.
3. Conditional logic is used to categorize films into eras based on their production year.
4. The `HAVING` clause filters results to consider only movies with more than two distinct actors, optimizing for films that have a notable cast.
5. The second part of the query finds related titles for the specified criteria and links them appropriately, focusing on prequels.
6. Overall, this SQL query is designed to benchmark complex performance scenarios with multiple join types and conditions.
