
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank
    FROM 
        title AS m
    WHERE 
        m.production_year IS NOT NULL
),
CastCustomer AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(a.name, ', ') AS actors
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        MAX(ct.kind) AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cc.cast_count,
        cc.actors,
        ci.companies,
        ci.company_type
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        CastCustomer AS cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        CompanyInfo AS ci ON rm.movie_id = ci.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    fm.title,
    COALESCE(fm.production_year::TEXT, 'Unknown') AS year,
    COALESCE(fm.cast_count, 0) AS total_cast,
    COALESCE(fm.actors, 'None') AS actor_names,
    COALESCE(fm.companies, 'No Companies') AS production_companies,
    COALESCE(fm.company_type, 'Not Specified') AS type_of_company
FROM 
    FilteredMovies AS fm
ORDER BY 
    fm.production_year DESC;
