WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
        AND t.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        cty.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY co.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type cty ON mc.company_type_id = cty.id
),
FinalResults AS (
    SELECT 
        rm.aka_id,
        rm.aka_name,
        rm.movie_title,
        rm.production_year,
        rm.year_rank,
        rm.cast_count,
        ci.company_name,
        ci.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyInfo ci ON rm.id = ci.movie_id
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    aka_id,
    aka_name,
    movie_title,
    production_year,
    cast_count,
    COALESCE(company_name, 'Independent') AS producing_company,
    COALESCE(company_type, 'N/A') AS company_category
FROM 
    FinalResults
ORDER BY 
    production_year DESC, cast_count DESC;
