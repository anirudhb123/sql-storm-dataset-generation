WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
),
actor_details AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY
        a.id, a.name
),
final_output AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        ad.actor_id,
        ad.actor_name,
        ad.movie_count,
        md.company_name,
        md.keyword
    FROM
        movie_details md
    JOIN
        cast_info ci ON md.movie_id = ci.movie_id
    JOIN
        actor_details ad ON ci.person_id = ad.actor_id
    ORDER BY
        md.production_year DESC,
        ad.movie_count DESC
)
SELECT
    movie_id,
    title,
    production_year,
    actor_id,
    actor_name,
    movie_count,
    company_name,
    keyword
FROM
    final_output
LIMIT 100;
