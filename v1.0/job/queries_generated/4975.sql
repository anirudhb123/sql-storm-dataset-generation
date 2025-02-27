WITH MovieYears AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rn
    FROM 
        MovieYears
),
SelectedMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_count
    FROM 
        TopMovies
    WHERE 
        rn <= 3
),
CompanyStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        aka_title m ON mc.movie_id = m.id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.movie_id
)
SELECT 
    sm.movie_title,
    sm.production_year,
    sm.actor_count,
    coalesce(cs.company_count, 0) AS total_companies,
    CASE 
        WHEN cs.company_count IS NULL THEN 'No Companies'
        ELSE 'Companies Present'
    END AS company_presence,
    string_agg(cn.name, ', ') AS company_names
FROM 
    SelectedMovies sm
LEFT JOIN 
    CompanyStats cs ON sm.movie_title = (SELECT title FROM aka_title WHERE id = cs.movie_id)
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = sm.movie_title AND production_year = sm.production_year)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    sm.movie_title, sm.production_year, sm.actor_count, cs.company_count
ORDER BY 
    sm.production_year, sm.actor_count DESC;
