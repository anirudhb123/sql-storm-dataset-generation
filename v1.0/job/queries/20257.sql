
WITH RECURSIVE actor_hierarchy AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS movie_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        complete_cast cc ON c.movie_id = cc.movie_id
    GROUP BY
        c.person_id, a.name
),
ranked_actors AS (
    SELECT
        *,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM
        actor_hierarchy
),
most_prolific_actors AS (
    SELECT *
    FROM ranked_actors
    WHERE actor_rank <= 10
),
actor_movie_info AS (
    SELECT
        pa.actor_name,
        COALESCE(m.title, 'Unknown Title') AS movie_title,
        COALESCE(mi.info, 'No Info') AS movie_info
    FROM
        most_prolific_actors pa
    JOIN
        cast_info ci ON pa.person_id = ci.person_id
    LEFT JOIN
        aka_title m ON ci.movie_id = m.movie_id
    LEFT JOIN
        movie_info mi ON mi.movie_id = ci.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
)
SELECT
    actor_name,
    STRING_AGG(movie_title, ', ') AS movies,
    STRING_AGG(movie_info, '; ') AS movie_details,
    COUNT(DISTINCT movie_title) AS total_movies,
    MAX(CHAR_LENGTH(movie_info)) AS max_info_length
FROM
    actor_movie_info
WHERE
    actor_name IS NOT NULL
GROUP BY
    actor_name
HAVING 
    COUNT(DISTINCT movie_title) > 2
ORDER BY
    total_movies DESC;
