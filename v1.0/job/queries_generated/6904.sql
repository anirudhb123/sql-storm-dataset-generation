WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        title, production_year, cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
)
SELECT 
    trm.production_year, 
    AVG(trm.cast_count) AS average_cast_count, 
    STRING_AGG(trm.title, ', ') AS top_titles
FROM 
    TopRankedMovies trm
GROUP BY 
    trm.production_year
ORDER BY 
    trm.production_year DESC;
