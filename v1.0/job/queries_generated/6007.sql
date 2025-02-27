WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        c.name AS company_name, 
        COUNT(ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, c.name
), 
TopRankedMovies AS (
    SELECT 
        title, 
        production_year, 
        company_name, 
        cast_count,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    title,
    production_year,
    company_name,
    cast_count
FROM 
    TopRankedMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, cast_count DESC;
