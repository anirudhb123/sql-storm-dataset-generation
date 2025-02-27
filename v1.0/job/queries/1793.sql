
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS rank,
        COALESCE(c.company_count, 0) AS company_count
    FROM 
        aka_title a
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(*) AS company_count
        FROM 
            movie_companies
        GROUP BY 
            movie_id
    ) c ON a.id = c.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        company_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    CASE 
        WHEN tm.company_count = 0 THEN 'No Companies'
        ELSE 'Companies Exist'
    END AS company_status
FROM 
    TopMovies tm
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE 
            mi.movie_id = (
                SELECT id 
                FROM aka_title 
                WHERE title = tm.title AND production_year = tm.production_year
                LIMIT 1
            )
            AND it.info = 'Synopsis'
    )
ORDER BY 
    tm.production_year DESC,
    tm.title ASC
LIMIT 10;
