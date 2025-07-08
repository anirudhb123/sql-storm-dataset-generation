
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies 
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        ci.companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyInfo ci ON rm.title_id = ci.movie_id
    WHERE 
        rm.actor_count > 5
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.companies, 'No companies associated') AS company_names,
    CASE 
        WHEN fm.actor_count IS NULL THEN 'No actors'
        ELSE CONCAT(fm.actor_count, ' actors')
    END AS actor_details
FROM 
    FilteredMovies fm
WHERE 
    fm.production_year >= 2000
ORDER BY 
    fm.production_year DESC, 
    fm.actor_count DESC;
