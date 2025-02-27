WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(CASE 
                WHEN ai.info_type_id = 1 THEN LENGTH(ai.info)  
                ELSE NULL 
            END) AS avg_synopsis_length
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        movie_info ai ON at.id = ai.movie_id AND ai.info_type_id IN (1, 2)  
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.company_count,
        rm.avg_synopsis_length,
        RANK() OVER (ORDER BY rm.avg_synopsis_length DESC, rm.company_count DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.avg_synopsis_length,
    ct.kind AS company_type
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.rank <= 10  
ORDER BY 
    tm.rank;