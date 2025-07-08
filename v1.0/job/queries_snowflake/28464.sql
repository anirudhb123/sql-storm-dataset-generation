
WITH filtered_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        aka_title AS t
    JOIN
        movie_keyword AS mk ON mk.movie_id = t.id
    JOIN
        keyword AS k ON k.id = mk.keyword_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id
),
cast_details AS (
    SELECT
        ci.movie_id,
        ac.name AS actor_name,
        ac.surname_pcode,
        ci.nr_order,
        role.role AS actor_role
    FROM
        cast_info AS ci
    JOIN
        aka_name AS ac ON ac.person_id = ci.person_id
    JOIN
        role_type AS role ON role.id = ci.role_id
    ORDER BY
        ci.nr_order
),
company_info AS (
    SELECT
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types
    FROM
        movie_companies AS mc
    JOIN
        company_name AS cn ON cn.id = mc.company_id
    JOIN
        company_type AS ct ON ct.id = mc.company_type_id
    GROUP BY
        mc.movie_id
),
movie_summary AS (
    SELECT
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.keywords,
        cd.actor_name,
        cd.surname_pcode,
        cd.actor_role,
        ci.companies,
        ci.company_types,
        COUNT(DISTINCT cd.actor_name) AS actor_count
    FROM
        filtered_movies AS fm
    LEFT JOIN
        cast_details AS cd ON cd.movie_id = fm.movie_id
    LEFT JOIN
        company_info AS ci ON ci.movie_id = fm.movie_id
    GROUP BY
        fm.movie_id, fm.title, fm.production_year, fm.keywords, 
        cd.actor_name, cd.surname_pcode, cd.actor_role, 
        ci.companies, ci.company_types
)
SELECT
    ms.title,
    ms.production_year,
    ms.keywords,
    ms.actor_count,
    ms.companies,
    ms.company_types
FROM
    movie_summary AS ms
WHERE
    ms.actor_count > 2
ORDER BY
    ms.production_year DESC, 
    ms.title;
