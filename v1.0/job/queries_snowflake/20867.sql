
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.kind_id DESC) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
),

ActorMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),

CompanyMovies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),

FilteredMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        am.actor_count,
        cm.companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.title_id = am.movie_id
    LEFT JOIN 
        CompanyMovies cm ON rm.title_id = cm.movie_id
    WHERE 
        rm.rn = 1
        AND (am.actor_count IS NULL OR am.actor_count > 3)
        AND (cm.companies IS NOT NULL AND cm.companies != '')
)

SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.actor_count, 0) AS actor_count,
    COALESCE(fm.companies, 'No Companies') AS companies_info,
    CASE 
        WHEN fm.production_year < 2000 THEN 'Classic'
        WHEN fm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = fm.title_id)) AS distinct_actor_names
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC
LIMIT 10
OFFSET 5;
