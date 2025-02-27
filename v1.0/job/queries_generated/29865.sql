WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        COALESCE(GROUP_CONCAT(DISTINCT c.name ORDER BY c.nr_order), 'No Cast') AS cast_list,
        COALESCE(GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword), 'No Keywords') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
CompanyData AS (
    SELECT 
        mc.movie_id, 
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FinalBenchmark AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        rm.cast_list,
        rm.keywords,
        COALESCE(cd.companies, 'No Companies') AS companies_list,
        COALESCE(cd.company_types, 'No Company Types') AS company_types_list
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyData cd ON rm.movie_id = cd.movie_id
)
SELECT 
    movie_id, 
    title, 
    production_year, 
    cast_list, 
    keywords, 
    companies_list, 
    company_types_list
FROM 
    FinalBenchmark
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, 
    title;
