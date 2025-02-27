
WITH ranked_movies AS (
    SELECT
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT aka_name.name) AS actor_names,
        ARRAY_AGG(DISTINCT keyword.keyword) AS keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM
        title
    JOIN
        movie_companies ON title.id = movie_companies.movie_id
    JOIN
        company_name ON movie_companies.company_id = company_name.id
    JOIN
        cast_info ON title.id = cast_info.movie_id
    JOIN
        aka_name ON cast_info.person_id = aka_name.person_id
    JOIN
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN
        keyword ON movie_keyword.keyword_id = keyword.id
    WHERE
        title.production_year >= 2000
        AND company_name.country_code = 'USA'
    GROUP BY
        title.id, title.title, title.production_year
),
top_movies AS (
    SELECT
        movie_id,
        title,
        production_year,
        actor_count,
        actor_names,
        keywords
    FROM
        ranked_movies
    WHERE
        rank <= 10
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names,
    tm.keywords,
    pi.info AS director_info
FROM
    top_movies tm
LEFT JOIN
    person_info pi ON pi.person_id IN (
        SELECT person_id
        FROM cast_info
        WHERE movie_id = tm.movie_id AND person_role_id = (SELECT id FROM role_type WHERE role = 'Director')
    )
ORDER BY
    tm.actor_count DESC;
