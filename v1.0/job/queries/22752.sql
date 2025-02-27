
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movie_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count,
        AVG(m.production_year) AS avg_production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    GROUP BY 
        ci.person_id
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT com.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name com ON mc.company_id = com.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    r.title,
    r.production_year,
    a.total_movies,
    a.notes_count,
    a.avg_production_year,
    COALESCE(cmc.company_count, 0) AS company_count
FROM 
    RankedMovies r
LEFT JOIN 
    ActorStats a ON r.rn = 1 AND r.production_year = a.avg_production_year
LEFT JOIN 
    CompanyMovieCount cmc ON r.title = (SELECT title FROM aka_title WHERE id = cmc.movie_id LIMIT 1)
WHERE 
    r.movie_count > 2
    AND (a.total_movies IS NULL OR a.notes_count > 0)
ORDER BY 
    r.production_year DESC, a.total_movies DESC;
