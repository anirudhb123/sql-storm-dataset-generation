
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title AS a
    LEFT JOIN 
        cast_info AS c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year, a.id
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
        mc.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    cm.companies
FROM 
    TopMovies AS tm
LEFT JOIN 
    CompanyMovies AS cm ON tm.title = (SELECT title FROM aka_title WHERE id = cm.movie_id)
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
