WITH movie_details AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        GROUP_CONCAT(DISTINCT aka_name.name) AS actor_names,
        GROUP_CONCAT(DISTINCT keyword.keyword) AS keywords,
        company_name.name AS company_name
    FROM title
    JOIN complete_cast ON complete_cast.movie_id = title.id
    JOIN cast_info ON cast_info.movie_id = complete_cast.movie_id
    JOIN aka_name ON aka_name.person_id = cast_info.person_id
    JOIN movie_companies ON movie_companies.movie_id = title.id
    JOIN company_name ON company_name.id = movie_companies.company_id
    JOIN movie_keyword ON movie_keyword.movie_id = title.id
    JOIN keyword ON keyword.id = movie_keyword.keyword_id
    WHERE title.production_year BETWEEN 2000 AND 2023
    GROUP BY title.id, company_name.name
),
company_details AS (
    SELECT 
        company_name.id AS company_id,
        company_name.name AS company_name,
        company_type.kind AS company_type
    FROM company_name
    JOIN movie_companies ON movie_companies.company_id = company_name.id
    JOIN company_type ON company_type.id = movie_companies.company_type_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    md.keywords,
    cd.company_name,
    cd.company_type
FROM movie_details md
JOIN company_details cd ON cd.company_name = md.company_name
ORDER BY md.production_year DESC, md.title;
