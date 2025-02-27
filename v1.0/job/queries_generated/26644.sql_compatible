
WITH movie_details AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT c.role_id::TEXT, ',') AS role_ids,
        STRING_AGG(DISTINCT a.name, ',') AS actors,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords
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
        m.id, m.title, m.production_year
),
high_rated_movies AS (
    SELECT
        md.movie_id,
        md.movie_title,
        md.production_year,
        COUNT(DISTINCT c.role_id) AS total_roles,
        COUNT(DISTINCT a.name) AS total_actors,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM
        movie_details md
    LEFT JOIN
        complete_cast cc ON md.movie_id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON md.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        md.production_year > 2000 
    GROUP BY
        md.movie_id, md.movie_title, md.production_year
    HAVING
        COUNT(DISTINCT a.name) > 2 
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
