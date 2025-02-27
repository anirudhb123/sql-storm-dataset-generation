WITH actor_movie_data AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS movie_year,
        r.role AS actor_role
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        title t ON c.movie_id = t.id
    JOIN
        role_type r ON c.role_id = r.id
),
keyword_info AS (
    SELECT
        t.id AS movie_id,
        k.keyword AS keyword
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
),
company_info AS (
    SELECT
        t.id AS movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
movie_details AS (
    SELECT
        am.actor_id,
        am.actor_name,
        am.movie_title,
        am.movie_year,
        am.actor_role,
        ki.keyword,
        ci.company_name,
        ci.company_type
    FROM
        actor_movie_data am
    LEFT JOIN
        keyword_info ki ON am.movie_title = ki.movie_id
    LEFT JOIN
        company_info ci ON am.movie_title = ci.movie_id
)
SELECT
    actor_id,
    actor_name,
    movie_title,
    movie_year,
    actor_role,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', '; ') AS companies
FROM
    movie_details
GROUP BY
    actor_id,
    actor_name,
    movie_title,
    movie_year,
    actor_role
ORDER BY
    movie_year DESC, actor_name;
