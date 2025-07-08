
WITH RankedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyMovies AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        aka_title mt ON mc.movie_id = mt.id
    GROUP BY 
        mt.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(cm.company_count, 0) AS company_count,
    CASE 
        WHEN tm.actor_count IS NULL THEN 'No actors'
        WHEN tm.actor_count >= 5 THEN 'Feature Film'
        ELSE 'Short Film' 
    END AS film_type
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovies cm ON cm.movie_id = (SELECT id FROM aka_title WHERE title = tm.title)
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
