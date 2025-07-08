
WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title, 
        COUNT(DISTINCT ci.person_id) AS cast_count, 
        ARRAY_AGG(DISTINCT akn.name) AS aka_names, 
        mt.production_year 
    FROM 
        aka_title at 
    JOIN 
        title mt ON at.movie_id = mt.id 
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id 
    JOIN 
        aka_name akn ON ci.person_id = akn.person_id 
    GROUP BY 
        mt.title, 
        mt.production_year 
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        STRING_AGG(DISTINCT cn.name, ', ') AS companies, 
        ct.kind AS company_type 
    FROM 
        movie_companies mc 
    JOIN 
        company_name cn ON mc.company_id = cn.id 
    JOIN 
        company_type ct ON mc.company_type_id = ct.id 
    GROUP BY 
        mc.movie_id, 
        ct.kind 
) 
SELECT 
    RM.movie_title, 
    RM.cast_count, 
    RM.aka_names, 
    RM.production_year, 
    CD.companies, 
    CD.company_type 
FROM 
    RankedMovies RM 
LEFT JOIN 
    CompanyDetails CD ON RM.production_year = CD.movie_id 
WHERE 
    RM.cast_count > 5 
ORDER BY 
    RM.production_year DESC, 
    RM.cast_count DESC 
LIMIT 50;
