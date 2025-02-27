
WITH MovieTitles AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS alternative_titles
    FROM 
        title
    LEFT JOIN 
        aka_title ON title.id = aka_title.movie_id
    LEFT JOIN 
        aka_name ON aka_title.id = aka_name.id
    GROUP BY 
        title.id, title.title, title.production_year
),
CastDetails AS (
    SELECT 
        cast_info.movie_id,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT name.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT role_type.role, ', ') AS roles_played
    FROM 
        cast_info
    JOIN 
        name ON cast_info.person_id = name.imdb_id
    JOIN 
        role_type ON cast_info.role_id = role_type.id
    GROUP BY 
        cast_info.movie_id
),
CompanyInfo AS (
    SELECT 
        movie_companies.movie_id,
        STRING_AGG(DISTINCT company_name.name, ', ') AS production_companies,
        STRING_AGG(DISTINCT company_type.kind, ', ') AS company_types
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        company_type ON movie_companies.company_type_id = company_type.id
    GROUP BY 
        movie_companies.movie_id
)

SELECT 
    mt.movie_id,
    mt.movie_title,
    mt.production_year,
    cd.cast_count,
    cd.actor_names,
    cd.roles_played,
    ci.production_companies,
    ci.company_types
FROM 
    MovieTitles mt
LEFT JOIN 
    CastDetails cd ON mt.movie_id = cd.movie_id
LEFT JOIN 
    CompanyInfo ci ON mt.movie_id = ci.movie_id
ORDER BY 
    mt.production_year DESC, mt.movie_title;
