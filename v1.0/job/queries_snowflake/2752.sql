WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT c.name) AS company_count,
        MAX(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS has_production_company
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        cm.company_count, 
        cm.has_production_company
    FROM 
        RankedMovies rm
    JOIN 
        CompanyStats cm ON rm.movie_id = cm.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title, 
    tm.company_count, 
    tm.has_production_company, 
    CASE 
        WHEN tm.has_production_company = 1 THEN 'Yes' 
        ELSE 'No' 
    END AS has_production_flag
FROM 
    TopMovies tm
ORDER BY 
    tm.company_count DESC, 
    tm.title;
