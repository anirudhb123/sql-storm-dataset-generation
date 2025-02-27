WITH RankedMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        actor_name, 
        movie_title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 3
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies_involved
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.actor_name,
    tm.movie_title,
    tm.production_year,
    COALESCE(mc.companies_involved, 'No companies listed') AS companies,
    COUNT(DISTINCT km.keyword) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id LIMIT 1)
LEFT JOIN 
    keyword km ON mk.keyword_id = km.id
LEFT JOIN 
    MovieCompanies mc ON (mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1))
GROUP BY 
    tm.actor_name, tm.movie_title, tm.production_year, mc.companies_involved
ORDER BY 
    tm.actor_name, tm.production_year DESC;
