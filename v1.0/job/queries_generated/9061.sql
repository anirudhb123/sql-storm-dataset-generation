WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        COUNT(DISTINCT ka.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ka.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ka ON cc.subject_id = ka.id
    WHERE 
        t.production_year >= 2000
        AND c.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year, c.name
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.company_name,
    rm.cast_count
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
