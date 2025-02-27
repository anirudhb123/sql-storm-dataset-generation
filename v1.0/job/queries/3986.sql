WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.title, t.production_year
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) as company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    COALESCE(fc.company_count, 0) AS company_count,
    CASE 
        WHEN rm.actor_count > 10 THEN 'High'
        WHEN rm.actor_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS actor_group
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCompanies fc ON rm.title = (SELECT title FROM aka_title WHERE id = fc.movie_id LIMIT 1)
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
