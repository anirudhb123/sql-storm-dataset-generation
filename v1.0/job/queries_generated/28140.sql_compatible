
WITH movie_details AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS aliases,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name.name, ', ') AS production_companies
    FROM title
    INNER JOIN aka_title ON title.id = aka_title.movie_id
    LEFT JOIN aka_name ON aka_title.title = aka_name.name
    LEFT JOIN movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN keyword ON movie_keyword.keyword_id = keyword.id
    LEFT JOIN movie_companies ON title.id = movie_companies.movie_id
    LEFT JOIN company_name ON movie_companies.company_id = company_name.id
    WHERE title.production_year >= 2000 
    GROUP BY title.id, title.title, title.production_year
),
cast_details AS (
    SELECT 
        movie_id,
        STRING_AGG(DISTINCT char_name.name || ' (' || role_type.role || ')', ', ') AS cast_info
    FROM cast_info
    INNER JOIN char_name ON cast_info.person_id = char_name.imdb_id
    INNER JOIN role_type ON cast_info.role_id = role_type.id
    GROUP BY movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.aliases,
    md.keywords,
    md.production_companies,
    cd.cast_info
FROM movie_details md
LEFT JOIN cast_details cd ON md.movie_id = cd.movie_id
ORDER BY md.production_year DESC, md.movie_title;
