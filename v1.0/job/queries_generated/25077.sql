WITH movie_cast AS (
    SELECT
        a.title AS movie_title,
        p.name AS actor_name,
        c.nr_order AS cast_order,
        r.role AS role_description
    FROM
        aka_title a
    JOIN
        cast_info c ON a.id = c.movie_id
    JOIN
        aka_name p ON c.person_id = p.person_id
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        a.production_year >= 2000
        AND p.name IS NOT NULL
    ORDER BY
        a.production_year, c.nr_order
),
company_info AS (
    SELECT
        m.id AS movie_id,
        co.name AS company_name,
        cl.kind AS company_type,
        m.production_year
    FROM
        movie_companies m
    JOIN
        company_name co ON m.company_id = co.id
    JOIN
        company_type cl ON m.company_type_id = cl.id
    WHERE
        m.note IS NULL
),
keyword_info AS (
    SELECT
        m.movie_id,
        k.keyword AS keyword
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
)
SELECT
    mc.movie_title,
    mc.actor_name,
    mc.cast_order,
    mc.role_description,
    ci.company_name,
    ci.company_type,
    ki.keyword
FROM
    movie_cast mc
LEFT JOIN
    company_info ci ON mc.movie_title = ci.movie_name
LEFT JOIN
    keyword_info ki ON mc.movie_id = ki.movie_id
WHERE
    mc.role_description NOT IN ('Cameo', 'Uncredited')
ORDER BY
    mc.production_year DESC, mc.cast_order;
