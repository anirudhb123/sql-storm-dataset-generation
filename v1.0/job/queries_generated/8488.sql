WITH movie_data AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names
    FROM
        title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    WHERE
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY
        t.id, ak.id
),
average_movies_per_actor AS (
    SELECT
        actor_id,
        COUNT(title_id) AS movie_count
    FROM
        movie_data
    GROUP BY
        actor_id
),
top_actors AS (
    SELECT
        md.actor_id,
        md.actor_name,
        amp.movie_count
    FROM
        movie_data md
    JOIN
        average_movies_per_actor amp ON md.actor_id = amp.actor_id
    ORDER BY
        amp.movie_count DESC
    LIMIT 10
)
SELECT
    ta.actor_name,
    ta.movie_count,
    GROUP_CONCAT(DISTINCT md.title) AS titles,
    GROUP_CONCAT(DISTINCT md.keywords) AS keywords,
    GROUP_CONCAT(DISTINCT md.company_names) AS companies
FROM
    top_actors ta
JOIN
    movie_data md ON ta.actor_id = md.actor_id
GROUP BY
    ta.actor_id, ta.actor_name, ta.movie_count
ORDER BY
    ta.movie_count DESC;
