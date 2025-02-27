WITH movie_data AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        GROUP_CONCAT(DISTINCT aka_name.name) AS aka_names,
        GROUP_CONCAT(DISTINCT char_name.name) AS char_names,
        GROUP_CONCAT(DISTINCT company_name.name) AS company_names,
        GROUP_CONCAT(DISTINCT keyword.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT role_type.role) AS roles,
        COUNT(DISTINCT cast_info.person_id) AS total_cast
    FROM title
    LEFT JOIN movie_companies ON title.id = movie_companies.movie_id
    LEFT JOIN company_name ON movie_companies.company_id = company_name.id
    LEFT JOIN movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN keyword ON movie_keyword.keyword_id = keyword.id
    LEFT JOIN complete_cast ON title.id = complete_cast.movie_id
    LEFT JOIN cast_info ON complete_cast.subject_id = cast_info.id
    LEFT JOIN aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN char_name ON aka_name.person_id = char_name.imdb_id
    LEFT JOIN role_type ON cast_info.role_id = role_type.id
    WHERE title.production_year >= 2000 -- Filtering for movies from 2000 onwards
    GROUP BY title.id
),
benchmark_data AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        aka_names,
        char_names,
        company_names,
        keywords,
        roles,
        total_cast,
        RANK() OVER (ORDER BY production_year DESC, total_cast DESC) AS rank
    FROM movie_data
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    aka_names,
    char_names,
    company_names,
    keywords,
    roles,
    total_cast,
    rank
FROM benchmark_data
WHERE rank <= 100 -- Limit to top 100 based on the rank
ORDER BY production_year DESC, total_cast DESC;
