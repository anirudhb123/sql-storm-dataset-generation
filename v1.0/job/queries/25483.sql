WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        pt.kind AS company_type
    FROM
        aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN company_type pt ON mc.company_type_id = pt.id
    WHERE
        t.production_year >= 2000
        AND k.keyword IS NOT NULL
),
actor_details AS (
    SELECT
        ca.movie_id,
        a.name AS actor_name,
        r.role AS actor_role
    FROM
        cast_info ca
    JOIN aka_name a ON ca.person_id = a.person_id
    JOIN role_type r ON ca.role_id = r.id
),
final_benchmark AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        ARRAY_AGG(DISTINCT md.keyword) AS keywords,
        ARRAY_AGG(DISTINCT ad.actor_name) AS actors,
        ARRAY_AGG(DISTINCT ad.actor_role) AS roles,
        COUNT(DISTINCT md.company_name) AS company_count
    FROM
        movie_details md
    LEFT JOIN actor_details ad ON md.movie_id = ad.movie_id
    GROUP BY
        md.movie_id, md.title, md.production_year
)
SELECT
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.keywords,
    fb.actors,
    fb.roles,
    fb.company_count
FROM
    final_benchmark fb
ORDER BY
    fb.production_year DESC, fb.title ASC;
