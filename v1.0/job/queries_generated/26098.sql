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
        person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = 1 -- Assuming info_type_id 1 is for biography
    WHERE
        t.production_year >= 2000 -- Filtering for movies produced after 2000
),
aggregated_data AS (
    SELECT
        movie_id,
        title,
        production_year,
        GROUP_CONCAT(DISTINCT company_name ORDER BY company_name) AS companies,
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
    COUNT(ad.actors) AS actor_count
FROM
    aggregated_data ad
WHERE
    ad.actor_count > 2 -- Only showing movies with more than 2 actors
ORDER BY
    ad.production_year DESC, ad.title ASC
LIMIT 10; -- Limiting the final results to the top 10 movies
