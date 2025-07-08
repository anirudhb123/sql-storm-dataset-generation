
WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE
        c.movie_id IN (
            SELECT id FROM aka_title WHERE production_year = 2023
        )
    
    UNION ALL
    
    SELECT
        c.person_id,
        ah.actor_name,
        ah.level + 1
    FROM
        ActorHierarchy ah
    JOIN cast_info c ON ah.person_id = c.person_id
    WHERE
        c.movie_id IN (
            SELECT linked_movie_id FROM movie_link 
            WHERE link_type_id IN (
                SELECT id FROM link_type WHERE link = 'franchise'
            )
        )
)
SELECT
    a.actor_name,
    COUNT(*) AS total_movies,
    AVG(m.production_year) AS avg_year,
    LISTAGG(DISTINCT ti.title, ', ') WITHIN GROUP (ORDER BY ti.title) AS titles,
    MAX(m.production_year) AS latest_movie_year
FROM
    ActorHierarchy a
JOIN cast_info c ON a.person_id = c.person_id
JOIN aka_title m ON c.movie_id = m.movie_id
LEFT JOIN title ti ON ti.id = m.id
GROUP BY
    a.actor_name
HAVING
    COUNT(*) > 5 AND
    MAX(m.production_year) >= 2020
ORDER BY
    total_movies DESC;
