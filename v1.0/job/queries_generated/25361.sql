WITH movie_summary AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    GROUP BY t.id, t.title, t.production_year
),

production_details AS (
    SELECT
        ms.movie_id,
        ms.movie_title,
        ms.production_year,
        ms.actor_names,
        ms.actor_count,
        ms.production_company_count,
        ct.kind AS company_type
    FROM movie_summary ms
    JOIN movie_companies mc ON ms.movie_id = mc.movie_id
    JOIN company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    pd.movie_id,
    pd.movie_title,
    pd.production_year,
    pd.actor_names,
    pd.actor_count,
    pd.production_company_count,
    STRING_AGG(DISTINCT pd.company_type, ', ') AS production_types
FROM production_details pd
WHERE pd.production_year >= 2000
GROUP BY pd.movie_id, pd.movie_title, pd.production_year, pd.actor_names, pd.actor_count, pd.production_company_count
ORDER BY pd.production_year DESC, pd.movie_title;
