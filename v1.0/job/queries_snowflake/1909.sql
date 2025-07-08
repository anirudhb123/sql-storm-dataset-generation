
WITH MovieRankings AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cm ON at.id = cm.movie_id
    LEFT JOIN 
        cast_info cc ON cm.subject_id = cc.id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        MovieRankings
    WHERE 
        rank <= 5
),
CompanyStatistics AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cs.company_count, 0) AS total_companies,
    COALESCE(cs.company_names, 'None') AS companies_involved
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyStatistics cs ON tm.title = (SELECT title FROM aka_title WHERE id = cs.movie_id)
ORDER BY 
    tm.production_year DESC, 
    total_companies DESC;
