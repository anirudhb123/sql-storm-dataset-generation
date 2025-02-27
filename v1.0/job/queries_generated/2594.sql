WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rn,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
RecentMovies AS (
    SELECT 
        title,
        production_year,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
CompanyInfo AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name), 'No Company') AS companies
    FROM 
        movie_companies mc
    JOIN 
        aka_title m ON mc.movie_id = m.id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_names,
    ci.companies
FROM 
    RecentMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.title = ci.title AND rm.production_year = ci.production_year
WHERE 
    rm.projection_year >= (SELECT MAX(production_year) - 10 FROM aka_title)
ORDER BY 
    rm.production_year DESC, rm.title;
