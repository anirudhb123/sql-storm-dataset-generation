WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as rank_by_year
    FROM 
        aka_title a
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
CompanyInfo AS (
    SELECT 
        c.name AS company_name,
        m.production_year,
        COUNT(mc.movie_id) AS movie_count
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        c.name, m.production_year
    HAVING 
        COUNT(mc.movie_id) > 5
)
SELECT 
    r.title AS Movie_Title,
    r.production_year,
    c.company_name,
    COALESCE(c.movie_count, 0) AS Company_Movie_Count,
    (SELECT COUNT(*) 
     FROM cast_info ci 
     WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = r.title LIMIT 1)) AS Cast_Count
FROM 
    RankedMovies r
LEFT JOIN 
    CompanyInfo c ON r.production_year = c.production_year
WHERE 
    r.rank_by_year <= 10
ORDER BY 
    r.production_year DESC, Movie_Title;
