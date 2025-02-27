WITH MovieData AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        aka_name.name AS person_name,
        role_type.role AS person_role,
        movie_info.info AS movie_info,
        keyword.keyword AS movie_keyword,
        company_name.name AS production_company
    FROM 
        title
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    JOIN 
        role_type ON cast_info.role_id = role_type.id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    LEFT JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    LEFT JOIN 
        company_name ON movie_companies.company_id = company_name.id
    WHERE 
        title.production_year >= 2000
        AND movie_info.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
        AND company_name.country_code = 'USA'
)

SELECT 
    movie_id,
    movie_title,
    COUNT(DISTINCT person_name) AS number_of_cast_members,
    STRING_AGG(DISTINCT person_name, ', ') AS cast_names,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    MIN(movie_info) AS synopsis,
    STRING_AGG(DISTINCT production_company, ', ') AS production_companies
FROM 
    MovieData
GROUP BY 
    movie_id, movie_title
ORDER BY 
    movie_title;
