WITH MovieDetails AS (
    SELECT 
        title.title AS movie_title,
        aka_title.production_year,
        company_name.name AS company_name,
        role_type.role AS role_name,
        person_info.info AS person_info
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        complete_cast ON aka_title.id = complete_cast.movie_id
    JOIN 
        cast_info ON complete_cast.id = cast_info.movie_id
    JOIN 
        role_type ON cast_info.role_id = role_type.id
    JOIN 
        person_info ON cast_info.person_id = person_info.person_id
    JOIN 
        movie_companies ON aka_title.movie_id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    WHERE 
        aka_title.production_year BETWEEN 2000 AND 2020
        AND person_info.info_type_id IN (
            SELECT id FROM info_type WHERE info LIKE '%Award%'
        )
        AND role_type.role IN ('Actor', 'Director')
), AggregatedData AS (
    SELECT
        movie_title,
        COUNT(DISTINCT company_name) AS num_companies,
        COUNT(DISTINCT role_name) AS num_roles
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
)
SELECT 
    movie_title,
    num_companies,
    num_roles
FROM 
    AggregatedData
ORDER BY 
    num_roles DESC, num_companies DESC
LIMIT 10;
