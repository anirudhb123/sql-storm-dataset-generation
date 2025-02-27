WITH actor_movie_count AS (
    SELECT
        ka.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        aka_name ka
    JOIN
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY
        ka.name
    HAVING
        COUNT(DISTINCT ci.movie_id) > 5
),
top_movies AS (
    SELECT
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        aka_title mt
    JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY
        mt.title, mt.production_year
    ORDER BY
        COUNT(DISTINCT mk.keyword_id) DESC
    LIMIT 10
),
actor_movie_keywords AS (
    SELECT
        am.actor_name,
        tm.title AS movie_title,
        tm.production_year,
        tm.keyword_count
    FROM
        actor_movie_count am
    JOIN
        cast_info ci ON am.actor_name = (SELECT name FROM aka_name WHERE person_id = ci.person_id)
    JOIN
        aka_title mt ON ci.movie_id = mt.id
    JOIN
        top_movies tm ON mt.title = tm.title AND mt.production_year = tm.production_year
)
SELECT
    am.actor_name,
    am.movie_title,
    am.production_year,
    am.keyword_count
FROM
    actor_movie_keywords am
ORDER BY
    am.keyword_count DESC, am.actor_name;
