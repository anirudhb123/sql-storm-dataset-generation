WITH MovieStats AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    GROUP BY a.id, a.title, a.production_year
),
ActorInfo AS (
    SELECT 
        p.name AS actor_name,
        p.id AS person_id,
        COUNT(DISTINCT c.movie_id) AS movies_appeared
    FROM aka_name p
    JOIN cast_info c ON p.person_id = c.person_id
    GROUP BY p.id, p.name
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.actor_count, 0) AS total_actors,
    (SELECT AVG(movies_appeared) FROM ActorInfo) AS avg_movies_per_actor,
    STRING_AGG(ai.actor_name, ', ') AS actor_list
FROM MovieStats m
LEFT JOIN ActorInfo ai ON ai.movies_appeared > 0 AND ai.movies_appeared < m.actor_count
WHERE m.production_year BETWEEN 2000 AND 2023
AND m.actor_count IS NOT NULL
GROUP BY m.title, m.production_year, m.actor_count
ORDER BY m.production_year DESC, m.title;
