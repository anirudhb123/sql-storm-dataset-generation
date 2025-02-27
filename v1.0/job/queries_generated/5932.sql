WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        aka_name.name AS actor_name,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY role_type.role) AS role_rank
    FROM 
        title
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    JOIN 
        cast_info ON complete_cast.subject_id = cast_info.person_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    JOIN 
        role_type ON cast_info.role_id = role_type.id
    WHERE 
        title.production_year >= 2000 
        AND company_name.country_code = 'USA'
)
SELECT 
    movie_title, 
    actor_name, 
    production_year,
    CASE 
        WHEN role_rank = 1 THEN 'Lead Actor'
        WHEN role_rank <= 3 THEN 'Supporting Actor'
        ELSE 'Minor Role'
    END AS role_description
FROM 
    RankedMovies
WHERE 
    role_rank <= 5
ORDER BY 
    production_year DESC, role_rank;
