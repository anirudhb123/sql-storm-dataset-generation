WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT m.company_id) AS total_companies,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cs.total_companies, 0) AS total_companies,
    COALESCE(cs.company_names, 'No Companies') AS company_names,
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = tm.movie_id) AS keyword_count,
    (SELECT GROUP_CONCAT(DISTINCT k.keyword) 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = tm.movie_id) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyStats cs ON tm.movie_id = cs.movie_id
WHERE 
    tm.production_year > 2000
ORDER BY 
    tm.production_year DESC, 
    total_companies DESC;
