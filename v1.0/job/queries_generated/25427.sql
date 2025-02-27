WITH movie_data AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aliases,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies
    FROM title m
    LEFT JOIN aka_title ak ON ak.movie_id = m.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN company_name c ON c.id = mc.company_id
    WHERE m.production_year BETWEEN 2000 AND 2023
    GROUP BY m.id
),
actor_data AS (
    SELECT
        p.id AS person_id,
        ak.name AS actor_name,
        GROUP_CONCAT(DISTINCT r.role) AS roles,
        GROUP_CONCAT(DISTINCT m.movie_id) AS movie_ids
    FROM aka_name ak
    JOIN cast_info ci ON ci.person_id = ak.person_id
    JOIN role_type r ON r.id = ci.role_id
    JOIN movie_companies mc ON mc.movie_id = ci.movie_id
    JOIN company_name cn ON cn.id = mc.company_id
    JOIN person_info pi ON pi.person_id = ak.person_id
    WHERE cn.country_code = 'US'
    GROUP BY p.id, ak.name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aliases,
    md.keywords,
    ad.actor_name,
    ad.roles
FROM movie_data md
JOIN actor_data ad ON md.movie_id IN (ad.movie_ids)
ORDER BY md.production_year DESC, md.movie_title;
