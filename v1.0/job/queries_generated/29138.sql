WITH RECURSIVE filmography AS (
    SELECT
        p.id AS actor_id,
        a.name AS actor_name,
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS co_actor_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title m ON c.movie_id = m.id
    JOIN
        complete_cast cc ON c.movie_id = cc.movie_id
    JOIN
        cast_info co ON cc.subject_id = co.id AND co.person_id != c.person_id
    JOIN
        info_type it ON cc.status_id = it.id
    WHERE
        it.info = 'completed'
    GROUP BY
        p.id, a.name, m.id, m.title, m.production_year
),
actor_movies AS (
    SELECT
        actor_id,
        actor_name,
        ARRAY_AGG(DISTINCT movie_title ORDER BY production_year DESC) AS movies
    FROM
        filmography
    GROUP BY
        actor_id, actor_name
)
SELECT
    am.actor_name,
    am.movies,
    COUNT(f.co_actor_count) AS total_co_actors,
    STRING_AGG(DISTINCT a.name, ', ') AS co_actors_list
FROM
    actor_movies am
JOIN
    filmography f ON am.actor_id = f.actor_id
LEFT JOIN
    aka_name a ON a.person_id IN (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id IN (SELECT UNNEST(am.movies)))
WHERE
    f.co_actor_count > 0
GROUP BY
    am.actor_name, am.movies
ORDER BY
    total_co_actors DESC;
