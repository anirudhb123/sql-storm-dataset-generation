WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_per_year <= 5
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL AND 
        cn.name IS NOT NULL AND 
        cn.name <> ''
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cc.company_count, 0) AS company_count,
    tm.cast_count,
    ARRAY_AGG(DISTINCT ak.name) AS aka_names
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovieCounts cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id = tm.movie_id)
GROUP BY 
    tm.title, tm.production_year, cc.company_count
HAVING 
    COUNT(DISTINCT ak.name) > 2 
    OR COUNT(*) FILTER (WHERE production_year > 2000) > 1
ORDER BY 
    tm.production_year DESC, 
    company_count DESC, 
    cast_count DESC;
