WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY b.id DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name b ON c.person_id = b.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    COALESCE(ci.companies, 'No companies') AS companies_involved,
    COALESCE(ci.company_types, 'No types') AS company_types,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyInfo ci ON tm.movie_title = ci.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
