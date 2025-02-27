WITH movie_actor_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
top_movies AS (
    SELECT
        mt.title,
        mt.production_year,
        mac.actor_count
    FROM
        aka_title mt
    JOIN
        movie_actor_counts mac ON mt.id = mac.movie_id
    WHERE
        mt.production_year >= 2000
    ORDER BY
        mac.actor_count DESC
    LIMIT 10
),
movie_genres AS (
    SELECT
        mt.id AS movie_id,
        k.keyword AS genre
    FROM
        aka_title mt
    JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(mg.genre, 'Undetermined') AS genre,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_actors,
    SUM(CASE WHEN ci.person_role_id IS NULL THEN 1 ELSE 0 END) AS unassigned_roles,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM
    top_movies tm
LEFT JOIN
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN
    movie_genres mg ON tm.movie_id = mg.movie_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY
    tm.title, tm.production_year, mg.genre
ORDER BY
    tm.production_year DESC, total_actors DESC;
