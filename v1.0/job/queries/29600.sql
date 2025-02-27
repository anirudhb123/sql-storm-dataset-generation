
WITH movie_details AS (
    SELECT
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        ARRAY_AGG(DISTINCT aka_name.name) AS aka_names,
        ARRAY_AGG(DISTINCT keyword.keyword) AS movie_keywords,
        ARRAY_AGG(DISTINCT company_name.name) AS production_companies
    FROM title
    LEFT JOIN aka_title ON title.id = aka_title.movie_id
    LEFT JOIN aka_name ON aka_title.id = aka_name.id
    LEFT JOIN movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN keyword ON movie_keyword.keyword_id = keyword.id
    LEFT JOIN movie_companies ON title.id = movie_companies.movie_id
    LEFT JOIN company_name ON movie_companies.company_id = company_name.id
    GROUP BY title.id, title.title, title.production_year
),
actor_performance AS (
    SELECT
        cast_info.movie_id,
        ARRAY_AGG(DISTINCT name.name) AS actor_names,
        SUM(CASE WHEN role_type.role = 'Lead' THEN 1 ELSE 0 END) AS lead_roles
    FROM cast_info
    JOIN name ON cast_info.person_id = name.imdb_id
    JOIN role_type ON cast_info.role_id = role_type.id
    GROUP BY cast_info.movie_id
)
SELECT
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.movie_keywords,
    md.production_companies,
    ap.actor_names,
    ap.lead_roles
FROM movie_details md
LEFT JOIN actor_performance ap ON md.movie_id = ap.movie_id
WHERE md.production_year >= 2000
ORDER BY md.production_year DESC, md.movie_title;
