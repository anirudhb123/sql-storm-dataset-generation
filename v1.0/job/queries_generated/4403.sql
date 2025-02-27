WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
),
CompanyMovies AS (
    SELECT 
        m.title,
        c.name AS company_name,
        c.country_code
    FROM 
        movie_companies mc
    JOIN 
        title m ON mc.movie_id = m.id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind LIKE 'Production%')
)
SELECT 
    tm.title,
    COALESCE(cm.company_name, 'Unknown') AS company_name,
    tm.production_year,
    tm.cast_count,
    SUM(CASE WHEN cm.company_name IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY tm.production_year) AS company_movie_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovies cm ON tm.title = cm.title AND tm.production_year = cm.production_year
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT id FROM title WHERE title = tm.title AND production_year = tm.production_year)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.title, cm.company_name, tm.production_year, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
