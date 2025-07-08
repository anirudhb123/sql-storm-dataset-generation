
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(cast_info.id) DESC) AS year_rank
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
CompanyCounts AS (
    SELECT 
        movie_companies.movie_id,
        COUNT(DISTINCT company_name.id) AS company_count
    FROM 
        movie_companies
    INNER JOIN 
        company_name ON movie_companies.company_id = company_name.id
    GROUP BY 
        movie_companies.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cc.company_count,
        COALESCE(cc.company_count, 0) AS effective_company_count,
        CASE 
            WHEN cc.company_count IS NULL THEN 'No Companies'
            ELSE 'Has Companies'
        END AS company_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyCounts cc ON rm.movie_id = cc.movie_id
    WHERE 
        rm.year_rank <= 3
)
SELECT 
    tm.title,
    tm.production_year,
    tm.effective_company_count,
    CASE 
        WHEN tm.effective_company_count > 5 THEN 'High'
        WHEN tm.effective_company_count BETWEEN 2 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS company_funding_level,
    (SELECT COUNT(*) FROM aka_title WHERE production_year = tm.production_year) AS titles_in_year,
    (SELECT LISTAGG(name.name, ', ') 
     FROM aka_name name 
     WHERE name.person_id IN (SELECT DISTINCT person_id FROM cast_info WHERE movie_id = tm.movie_id)) AS starring_actors
FROM 
    TopMovies tm
WHERE 
    tm.company_status = 'Has Companies'
ORDER BY 
    tm.production_year DESC, tm.effective_company_count DESC;
