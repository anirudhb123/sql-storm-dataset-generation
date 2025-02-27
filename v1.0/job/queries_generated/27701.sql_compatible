
WITH MovieCast AS (
    SELECT 
        title.title AS movie_title,
        aka_name.name AS actor_name,
        kind_type.kind AS movie_kind,
        title.production_year AS year,
        role_type.role AS role,
        title.id AS title_id
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        cast_info ON aka_title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    JOIN 
        role_type ON cast_info.role_id = role_type.id
    JOIN 
        kind_type ON title.kind_id = kind_type.id
),
KeywordData AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
),
CompanyData AS (
    SELECT 
        movie_id,
        STRING_AGG(company_name.name, ', ') AS companies
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    GROUP BY 
        movie_id
)

SELECT 
    mc.movie_title,
    mc.actor_name,
    mc.movie_kind,
    mc.year,
    mc.role,
    COALESCE(kd.keywords, '') AS keywords,
    COALESCE(cd.companies, '') AS companies
FROM 
    MovieCast mc
LEFT JOIN 
    KeywordData kd ON mc.title_id = kd.movie_id
LEFT JOIN 
    CompanyData cd ON mc.title_id = cd.movie_id
WHERE 
    mc.year >= 2000
ORDER BY 
    mc.year DESC, mc.actor_name;