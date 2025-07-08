
WITH RECURSIVE ActorHierarchies AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        1 AS hierarchy_level
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        t.production_year >= 2000

    UNION ALL

    SELECT
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        ah.hierarchy_level + 1
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    JOIN
        ActorHierarchies ah ON c.movie_id = ah.person_id
    WHERE
        t.production_year >= 2000
)

SELECT
    ah.actor_name,
    COUNT(DISTINCT ah.movie_title) AS movie_count,
    LISTAGG(DISTINCT ah.movie_title, ', ') WITHIN GROUP (ORDER BY ah.movie_title) AS movie_titles,
    MAX(ah.hierarchy_level) AS max_hierarchy_level
FROM
    ActorHierarchies ah
GROUP BY
    ah.actor_name
HAVING
    COUNT(DISTINCT ah.movie_title) > 5
ORDER BY
    movie_count DESC;
