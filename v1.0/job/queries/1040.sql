WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        a.production_year IS NOT NULL AND
        a.title IS NOT NULL
),
TopCompanies AS (
    SELECT 
        company_name,
        COUNT(*) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
    GROUP BY 
        company_name
    HAVING 
        COUNT(*) > 1
)
SELECT 
    rc.movie_title,
    rc.production_year,
    tc.company_name,
    COALESCE(tc.movie_count, 0) AS total_movies,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id IN (SELECT id FROM aka_title WHERE production_year = rc.production_year)
     AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice')
    ) AS box_office_info_count
FROM 
    RankedMovies rc
LEFT JOIN 
    TopCompanies tc ON rc.company_name = tc.company_name
WHERE 
    rc.year_rank <= 5 AND 
    rc.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rc.production_year DESC, 
    rc.movie_title;
