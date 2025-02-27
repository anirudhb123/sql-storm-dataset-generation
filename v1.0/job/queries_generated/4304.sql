WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighActorMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    ham.title,
    ham.production_year,
    ham.actor_count,
    COALESCE(cs.company_count, 0) AS company_count,
    COALESCE(cs.companies, 'None') AS companies
FROM 
    HighActorMovies ham
LEFT JOIN 
    CompanyStats cs ON ham.title = (SELECT title FROM aka_title WHERE id = cs.movie_id)
ORDER BY 
    ham.production_year DESC, ham.actor_count DESC;
