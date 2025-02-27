WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
), 
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(cm.company_name, 'Independent') AS production_company,
    CASE 
        WHEN rm.cast_count > 10 THEN 'Large Cast'
        WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size_label
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.title = (SELECT title FROM aka_title WHERE id = cm.movie_id LIMIT 1)
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 10;
