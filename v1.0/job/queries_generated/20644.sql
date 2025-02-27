WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY a.id) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
),

CorrelatedCasting AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

TopMovies AS (
    SELECT 
        rt.title,
        rt.production_year,
        rc.cast_count,
        rt.keyword_count
    FROM 
        RankedTitles rt
    INNER JOIN 
        CorrelatedCasting rc ON rt.id = rc.movie_id
    WHERE 
        rt.rn <= 5
),

CompanyRelations AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.keyword_count,
    COALESCE(cr.companies, 'No Company Info') AS companies
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyRelations cr ON tm.movie_id = cr.movie_id
ORDER BY 
    tm.production_year DESC,
    tm.cast_count DESC;
