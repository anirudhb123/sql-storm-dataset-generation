WITH movie_summary AS (
    SELECT 
        title.title AS movie_title,
        title.id AS movie_id,
        title.production_year,
        GROUP_CONCAT(DISTINCT aka_name.name ORDER BY aka_name.name SEPARATOR ', ') AS alternative_names,
        GROUP_CONCAT(DISTINCT keyword.keyword ORDER BY keyword.keyword SEPARATOR ', ') AS keywords,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        COUNT(DISTINCT company_name.id) AS total_companies
    FROM title
    LEFT JOIN aka_title ON title.id = aka_title.movie_id
    LEFT JOIN aka_name ON aka_title.id = aka_name.id
    LEFT JOIN movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN keyword ON movie_keyword.keyword_id = keyword.id
    LEFT JOIN cast_info ON title.id = cast_info.movie_id
    LEFT JOIN movie_companies ON title.id = movie_companies.movie_id
    LEFT JOIN company_name ON movie_companies.company_id = company_name.id
    GROUP BY title.id
),
person_summary AS (
    SELECT 
        name.name AS actor_name,
        COUNT(cast_info.movie_id) AS movies_count,
        STRING_AGG(DISTINCT title.title ORDER BY title.title) AS movies_list
    FROM name
    INNER JOIN cast_info ON name.id = cast_info.person_id
    INNER JOIN title ON cast_info.movie_id = title.id
    GROUP BY name.id
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.alternative_names,
    ms.keywords,
    ms.total_cast,
    ms.total_companies,
    ps.actor_name,
    ps.movies_count,
    ps.movies_list
FROM movie_summary ms
LEFT JOIN person_summary ps ON ps.movies_count > 0 AND ps.movies_count <= 5
WHERE ms.production_year >= 2000
ORDER BY ms.production_year DESC, ms.movie_title
LIMIT 50;
