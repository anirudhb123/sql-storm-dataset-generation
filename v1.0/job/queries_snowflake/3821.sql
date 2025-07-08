
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
FinalResult AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.actor_count,
        COALESCE(mc.company_count, 0) AS company_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieCompanies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = fm.title)
)
SELECT 
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.company_count,
    CASE 
        WHEN fr.actor_count IS NULL THEN 'No actors'
        WHEN fr.company_count IS NULL THEN 'No companies'
        ELSE 'Data available'
    END AS data_status
FROM 
    FinalResult fr
ORDER BY 
    fr.production_year DESC, fr.actor_count DESC;
