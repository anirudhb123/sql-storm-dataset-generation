
WITH MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        mt.movie_id
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.title, mt.production_year, mt.movie_id
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),

FinalBenchmark AS (
    SELECT 
        md.title,
        md.production_year,
        md.total_cast,
        md.cast_with_notes,
        cd.companies,
        cd.total_companies,
        md.movie_id
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
)

SELECT 
    title,
    production_year,
    total_cast,
    cast_with_notes,
    COALESCE(companies, 'No Companies') AS companies,
    COALESCE(total_companies, 0) AS total_companies,
    CASE 
        WHEN total_cast > 20 THEN 'Large Cast'
        WHEN total_cast BETWEEN 10 AND 20 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    FinalBenchmark
ORDER BY 
    production_year DESC, total_cast DESC;
