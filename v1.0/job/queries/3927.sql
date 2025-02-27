WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_within_year <= 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    cm.company_names,
    COALESCE(i.info, 'No additional info') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovies cm ON tm.title = (
        SELECT 
            title 
        FROM 
            aka_title 
        WHERE 
            id = cm.movie_id
    )
LEFT JOIN 
    movie_info i ON tm.production_year = i.id 
WHERE 
    (tm.production_year IS NOT NULL OR cm.company_names IS NOT NULL)
ORDER BY 
    tm.production_year DESC, 
    tm.title;
