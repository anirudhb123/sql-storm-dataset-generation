WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        a.name IS NOT NULL

    UNION ALL

    SELECT
        h.person_id,
        a.name AS actor_name,
        level + 1
    FROM
        ActorHierarchy h
    JOIN
        cast_info c ON h.person_id = c.person_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        a.name IS NOT NULL
)
SELECT
    a.actor_name,
    t.title,
    t.production_year,
    COUNT(DISTINCT c.movie_id) AS movies_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN AVG(m.info) IS NOT NULL THEN AVG(m.info::numeric) 
        ELSE 0 
    END AS avg_rating
FROM
    ActorHierarchy a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE
    t.production_year >= 2000 AND 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv'))
GROUP BY
    a.actor_name, t.title, t.production_year
HAVING
    COUNT(DISTINCT c.movie_id) > 2
ORDER BY 
    avg_rating DESC, movies_count DESC;
