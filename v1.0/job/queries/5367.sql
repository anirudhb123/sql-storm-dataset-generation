WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM
        title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.has_notes
    FROM
        ranked_movies rm
    WHERE
        rm.rank <= 5
),
actors_with_movies AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        tm.movie_id,
        tm.title AS movie_title
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        top_movies tm ON ci.movie_id = tm.movie_id
)
SELECT
    am.actor_name,
    STRING_AGG(am.movie_title, '; ') AS movies_featured,
    COUNT(DISTINCT am.movie_id) AS total_movies
FROM
    actors_with_movies am
GROUP BY
    am.actor_name
ORDER BY
    total_movies DESC;
