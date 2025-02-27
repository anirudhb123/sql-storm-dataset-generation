WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        i.info AS movie_info
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        movie_info mi ON t.id = mi.movie_id
    JOIN
        info_type i ON mi.info_type_id = i.id
    WHERE
        t.production_year > 2000
        AND i.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%box office%')
),
actor_details AS (
    SELECT
        a.person_id,
        a.name AS actor_name,
        c.movie_id,
        r.role AS actor_role
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        role_type r ON c.role_id = r.id
),
final_report AS (
    SELECT
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.movie_keyword,
        md.company_name,
        ad.actor_name,
        ad.actor_role
    FROM
        movie_details md
    LEFT JOIN
        actor_details ad ON md.movie_id = ad.movie_id
)
SELECT
    movie_id,
    movie_title,
    production_year,
    movie_keyword,
    company_name,
    STRING_AGG(DISTINCT actor_name || ' (' || actor_role || ')', ', ') AS actors
FROM
    final_report
GROUP BY
    movie_id, movie_title, production_year, movie_keyword, company_name
ORDER BY
    production_year DESC, movie_title;
