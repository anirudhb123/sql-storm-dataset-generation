WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_within_year
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        tm.actor_count,
        ci.companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        CompanyInfo ci ON tm.production_year = (SELECT production_year FROM title WHERE id = ci.movie_id)
)
SELECT 
    fr.movie_title,
    fr.production_year,
    fr.actor_count,
    COALESCE(fr.companies, 'No Companies') AS companies
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, 
    fr.actor_count DESC;
