
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year, actor_count
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
),
CompanyStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        movie_info m ON mc.movie_id = m.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cs.company_count, 0) AS company_count,
    COALESCE(cs.company_names, 'No companies') AS company_names,
    tm.actor_count
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyStats cs ON tm.movie_id = cs.movie_id
WHERE
    (tm.production_year > 2000 AND cs.company_count IS NOT NULL) OR
    (tm.production_year <= 2000 AND cs.company_count IS NULL)
ORDER BY 
    tm.production_year DESC, 
    tm.title;
