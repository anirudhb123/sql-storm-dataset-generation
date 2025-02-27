WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY m.id) AS avg_role_assignment
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        m.id
), CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')
    GROUP BY 
        mc.movie_id
), KeywordMovies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.avg_role_assignment,
        cm.companies,
        km.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovies cm ON rm.movie_id = cm.movie_id
    LEFT JOIN 
        KeywordMovies km ON rm.movie_id = km.movie_id
    WHERE 
        rm.production_year >= 2000
        AND (rm.total_cast > 0 OR cm.companies IS NOT NULL)
)
SELECT 
    *,
    CASE 
        WHEN total_cast > 10 THEN 'Large Cast'
        WHEN total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    FinalResults
ORDER BY 
    production_year DESC,
    total_cast DESC
LIMIT 100 OFFSET 0;
