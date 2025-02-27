WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        m2.id AS movie_id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m2 ON ml.linked_movie_id = m2.id
)

SELECT
    a.name AS actor_name,
    COALESCE(count_actors.actor_count, 0) AS actor_count,
    mh.title AS connected_movie,
    mh.production_year AS connected_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY mh.production_year DESC) AS rank,
    CASE 
        WHEN mh.production_year IS NULL THEN 'No Year'
        ELSE CASE 
            WHEN mh.production_year < 2000 THEN 'Classic'
            ELSE 'Modern'
        END
    END AS era
FROM
    aka_name a
LEFT JOIN
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN
    aka_title t ON ci.movie_id = t.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_hierarchy mh ON t.id = mh.movie_id
LEFT JOIN (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.person_id
) AS count_actors ON a.person_id = count_actors.person_id
WHERE
    a.name IS NOT NULL
    AND (mh.level IS NULL OR mh.level <= 1)
GROUP BY
    a.name, mh.title, mh.production_year, count_actors.actor_count
HAVING
    COUNT(DISTINCT ci.movie_id) > 1
ORDER BY
    actor_count DESC, mh.production_year DESC;

This SQL query performs the following:

1. Defines a recursive Common Table Expression (CTE) called `movie_hierarchy`, which builds a hierarchy of movies linked to each other.
2. Selects data about actors, including their names and the count of movies they have acted in.
3. Integrates various joins, including outer joins to include actors with no roles in linked movies.
4. Utilizes `STRING_AGG` to concatenate keywords associated with each movie.
5. Applies a `ROW_NUMBER` window function to rank actors by their most recent movies in descending order.
6. Implements conditional logic to categorize movies into 'Classic' and 'Modern' based on their production years.
7. Applies a `HAVING` clause to filter actors with more than one movie after grouping results. 

This query exemplifies complex SQL constructs and explores relationships among actors, movies, and keywords while accounting for NULL values and other edge cases.
