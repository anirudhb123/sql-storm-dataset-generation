WITH movie_details AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT c.role_id) AS role_ids,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM
        title m
    LEFT JOIN
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id
),
high_rated_movies AS (
    SELECT
        md.movie_id,
        md.movie_title,
        md.production_year,
        COUNT(DISTINCT md.role_ids) AS total_roles,
        COUNT(DISTINCT md.actors) AS total_actors,
        COUNT(DISTINCT md.keywords) AS total_keywords
    FROM
        movie_details md
    WHERE
        md.production_year > 2000 -- Filtering recent movies
    GROUP BY
        md.movie_id, md.movie_title, md.production_year
    HAVING
        COUNT(DISTINCT md.actors) > 2 -- Movies with more than 2 actors
)
SELECT
    h.movie_id,
    h.movie_title,
    h.production_year,
    h.total_roles,
    h.total_actors,
    h.total_keywords
FROM
    high_rated_movies h
ORDER BY
    h.total_actors DESC, h.production_year DESC
LIMIT 10;
