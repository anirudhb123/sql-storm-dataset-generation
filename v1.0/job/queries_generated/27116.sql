WITH movie_details AS (
    SELECT
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT co.name) AS company_names
    FROM
        title t
    JOIN
        movie_info mi ON t.id = mi.movie_id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        keyword k ON t.id = k.movie_id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name co ON mc.company_id = co.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT
        title_id,
        movie_title,
        production_year,
        CAST(COUNT(DISTINCT cast_names) AS INTEGER) AS num_cast,
        CAST(COUNT(DISTINCT keywords) AS INTEGER) AS num_keywords,
        CAST(COUNT(DISTINCT company_names) AS INTEGER) AS num_companies
    FROM
        movie_details
    GROUP BY
        title_id, movie_title, production_year
)
SELECT
    movie_title,
    production_year,
    num_cast,
    num_keywords,
    num_companies
FROM
    filtered_movies
ORDER BY
    production_year DESC,
    num_cast DESC,
    movie_title ASC
LIMIT 20;
