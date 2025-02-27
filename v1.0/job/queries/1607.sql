WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CombinedStats AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        COALESCE(cs.company_count, 0) AS company_count,
        COALESCE(cs.companies_involved, 'None') AS companies_involved,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyStats cs ON md.movie_id = cs.movie_id
)
SELECT 
    title,
    production_year,
    cast_count,
    company_count,
    companies_involved,
    rank
FROM 
    CombinedStats
WHERE 
    (production_year >= 2000 AND rank <= 10)
    OR (production_year < 2000 AND company_count > 0)
ORDER BY 
    production_year DESC, cast_count DESC;
