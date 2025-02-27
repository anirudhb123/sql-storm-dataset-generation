
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        COUNT(DISTINCT ci.role_id) AS num_roles
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON ci.movie_id = m.id
    JOIN 
        aka_name c ON c.person_id = ci.person_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS num_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
CompleteMovieData AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.movie_keyword,
        md.cast_names,
        md.num_roles,
        cd.num_companies,
        cd.companies
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    movie_keyword,
    cast_names,
    num_roles,
    num_companies,
    companies
FROM 
    CompleteMovieData
WHERE 
    production_year >= 2000
ORDER BY 
    num_roles DESC, production_year DESC
FETCH FIRST 50 ROWS ONLY;
