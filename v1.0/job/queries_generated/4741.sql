WITH RankedMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        a.name, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.actor_name,
    tm.movie_title,
    tm.production_year,
    COALESCE(cd.company_name, 'Unknown Company') AS company_name,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_category
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_title = cd.movie_name
ORDER BY 
    tm.production_year DESC, tm.actor_name;

