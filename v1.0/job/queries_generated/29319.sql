WITH Movie_Info AS (
    SELECT 
        title.title,
        title.production_year,
        title.kind_id,
        movie_info.info
    FROM title
    JOIN movie_info ON title.id = movie_info.movie_id
    WHERE movie_info.note IS NULL
),
Actor_Info AS (
    SELECT 
        aka_name.name AS actor_name,
        aka_name.person_id,
        cast_info.movie_id,
        role_type.role
    FROM cast_info
    JOIN aka_name ON cast_info.person_id = aka_name.person_id
    JOIN role_type ON cast_info.role_id = role_type.id
),
Company_Info AS (
    SELECT 
        company_name.name AS company_name,
        company_type.kind AS company_type,
        movie_companies.movie_id
    FROM movie_companies
    JOIN company_name ON movie_companies.company_id = company_name.id
    JOIN company_type ON movie_companies.company_type_id = company_type.id
),
Keyword_Info AS (
    SELECT 
        movie_keyword.movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM movie_keyword
    JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY movie_keyword.movie_id
)
SELECT 
    mi.title AS movie_title,
    mi.production_year,
    ai.actor_name,
    ai.role,
    ci.company_name,
    ci.company_type,
    ki.keywords
FROM Movie_Info mi
JOIN Actor_Info ai ON mi.id = ai.movie_id
JOIN Company_Info ci ON mi.id = ci.movie_id
LEFT JOIN Keyword_Info ki ON mi.id = ki.movie_id
WHERE mi.production_year BETWEEN 2000 AND 2023
ORDER BY mi.production_year DESC, mi.title;
