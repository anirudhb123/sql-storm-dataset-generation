
WITH ranked_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT a.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        aka_title AS m
    JOIN cast_info AS c ON m.id = c.movie_id
    JOIN aka_name AS a ON c.person_id = a.person_id
    LEFT JOIN movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN keyword AS k ON mk.keyword_id = k.id
    WHERE
        m.production_year >= 2000
    GROUP BY
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT
        movie_id,
        title,
        production_year,
        actor_count,
        actor_names,
        keywords,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM
        ranked_movies
)
SELECT
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names,
    tm.keywords
FROM
    top_movies tm
WHERE
    tm.rank <= 10
ORDER BY
    tm.actor_count DESC;
