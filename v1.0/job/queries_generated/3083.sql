WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
), 
TitleCompany AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_count,
        md.actor_names,
        cd.company_count,
        cd.company_names
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.title = cd.movie_id
)
SELECT 
    title, 
    production_year, 
    cast_count, 
    actor_names,
    COALESCE(company_count, 0) AS total_companies,
    COALESCE(company_names, 'No Companies') AS affiliated_companies
FROM 
    TitleCompany
WHERE 
    production_year IS NOT NULL
ORDER BY 
    production_year DESC, 
    cast_count DESC;
