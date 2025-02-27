WITH RECURSIVE ActorMovies AS (
    SELECT
        ca.person_id,
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM
        cast_info ca
    JOIN title t ON ca.movie_id = t.id
    WHERE
        ca.person_role_id = (SELECT id FROM role_type WHERE role = 'actor')
    
    UNION ALL
    
    SELECT
        ca.person_id,
        t.id AS movie_id,
        t.title,
        t.production_year,
        am.level + 1
    FROM
        ActorMovies am
    JOIN cast_info ca ON ca.movie_id IN (
        SELECT linked_movie_id 
        FROM movie_link ml 
        WHERE ml.movie_id = am.movie_id
    )
    JOIN title t ON ca.movie_id = t.id
    WHERE
        ca.person_role_id = (SELECT id FROM role_type WHERE role = 'actor')
)
SELECT
    ak.name AS actor_name,
    ARRAY_AGG(DISTINCT am.title ORDER BY am.production_year) AS movies,
    COUNT(DISTINCT am.movie_id) AS movie_count,
    COALESCE(mk.keyword, 'No Keyword') AS keyword_assigned
FROM
    ActorMovies am
JOIN aka_name ak ON am.person_id = ak.person_id
LEFT JOIN movie_keyword mk ON am.movie_id = mk.movie_id
WHERE
    ak.name IS NOT NULL
GROUP BY
    ak.name,
    mk.keyword
ORDER BY
    movie_count DESC
LIMIT 10;
