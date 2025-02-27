WITH ranked_movies AS (
    SELECT
        a.title AS movie_title,
        a.production_year,
        c.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_order
    FROM
        aka_title a
    JOIN
        cast_info c ON a.id = c.movie_id
    JOIN
        aka_name n ON c.person_id = n.person_id
    WHERE
        a.production_year >= 2000
        AND a.kind_id IN (
            SELECT id FROM kind_type WHERE kind LIKE '%Drama%'
        )
),
actor_count AS (
    SELECT
        actor_name,
        COUNT(*) AS movie_count
    FROM
        ranked_movies
    GROUP BY
        actor_name
    HAVING
        COUNT(*) > 5
),
movie_details AS (
    SELECT
        rm.movie_title,
        rm.production_year,
        ac.movie_count
    FROM
        ranked_movies rm
    JOIN
        actor_count ac ON rm.actor_name = ac.actor_name
    ORDER BY
        ac.movie_count DESC,
        rm.production_year DESC
)
SELECT
    md.movie_title,
    md.production_year,
    md.movie_count,
    STRING_AGG(md.actor_name, ', ') AS co_actors
FROM
    movie_details md
JOIN
    ranked_movies rm ON md.movie_title = rm.movie_title AND md.production_year = rm.production_year
GROUP BY
    md.movie_title, md.production_year, md.movie_count
ORDER BY
    md.movie_count DESC, md.production_year DESC
LIMIT 10;
