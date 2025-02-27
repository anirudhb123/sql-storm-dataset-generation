WITH RECURSIVE ActorHierarchy AS (
    SELECT
        ca.person_id,
        ca.movie_id,
        1 AS level,
        ak.name AS actor_name
    FROM
        cast_info ca
    JOIN
        aka_name ak ON ca.person_id = ak.person_id
    WHERE
        ak.name IS NOT NULL
    
    UNION ALL
    
    SELECT
        ca.person_id,
        ca.movie_id,
        ah.level + 1 AS level,
        ak.name AS actor_name
    FROM
        cast_info ca
    JOIN
        ActorHierarchy ah ON ca.movie_id = ah.movie_id
    JOIN
        aka_name ak ON ca.person_id = ak.person_id
    WHERE
        ak.name IS NOT NULL
)
SELECT
    a.actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    MAX(t.production_year) AS latest_movie_year,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords
FROM
    ActorHierarchy a
LEFT JOIN
    complete_cast c ON a.movie_id = c.movie_id
LEFT JOIN
    title t ON c.movie_id = t.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
WHERE
    a.level = 1  -- Only top-level actors
    AND t.production_year >= 2000 -- Filter for movies after the year 2000
GROUP BY
    a.actor_name
HAVING
    COUNT(DISTINCT c.movie_id) > 5  -- At least 6 movies
ORDER BY
    latest_movie_year DESC,
    total_movies DESC
LIMIT 10;
