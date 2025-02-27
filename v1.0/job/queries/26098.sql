
WITH movie_data AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        rt.role AS person_role,
        a.name AS actor_name,
        pi.info AS actor_info
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN
        person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = 1 
    WHERE
        t.production_year >= 2000 
),
aggregated_data AS (
    SELECT
        movie_id,
        title,
        production_year,
        STRING_AGG(DISTINCT company_name, ',' ORDER BY company_name) AS companies,
        STRING_AGG(DISTINCT actor_name || ' (' || person_role || ')', ', ') AS actors
    FROM
        movie_data
    GROUP BY
        movie_id, title, production_year
)
SELECT
    ad.movie_id,
    ad.title,
    ad.production_year,
    ad.companies,
    ad.actors,
    COUNT(*) AS actor_count
FROM
    aggregated_data ad
GROUP BY
    ad.movie_id,
    ad.title,
    ad.production_year,
    ad.companies,
    ad.actors
HAVING
    COUNT(*) > 2 
ORDER BY
    ad.production_year DESC, ad.title ASC
LIMIT 10;
