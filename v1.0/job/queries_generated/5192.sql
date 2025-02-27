WITH actor_movies AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS production_year,
        r.role AS role_type
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        title t ON ci.movie_id = t.id
    JOIN
        role_type r ON ci.role_id = r.id
    WHERE
        t.production_year >= 2000
),
company_movies AS (
    SELECT
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies m
    JOIN
        company_name c ON m.company_id = c.id
    JOIN
        company_type ct ON m.company_type_id = ct.id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
)
SELECT
    am.actor_id,
    am.actor_name,
    am.movie_title,
    am.production_year,
    am.role_type,
    cm.company_name,
    cm.company_type,
    mk.keyword
FROM
    actor_movies am
LEFT JOIN
    complete_cast cc ON am.movie_title = cc.subject_id
LEFT JOIN
    company_movies cm ON am.movie_title = cm.movie_id
LEFT JOIN
    movie_keywords mk ON am.movie_title = mk.movie_id
WHERE
    am.actor_id IS NOT NULL
ORDER BY
    am.production_year DESC, am.actor_name;
