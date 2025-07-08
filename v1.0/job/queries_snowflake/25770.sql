
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.name AS company_name,
        ci.role_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = t.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000 
        AND m.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year, m.name, ci.role_id
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_name,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rn
    FROM 
        RankedMovies
)

SELECT 
    tm.production_year,
    tm.title,
    tm.company_name,
    tm.cast_count
FROM 
    TopMovies tm
WHERE 
    tm.rn <= 5
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
