
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        COUNT(DISTINCT mc.company_id) AS company_count, 
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        company_count, 
        keyword_count,
        ROW_NUMBER() OVER (ORDER BY company_count DESC, keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id, 
    tm.title, 
    tm.production_year, 
    tm.company_count, 
    tm.keyword_count
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.company_count DESC, 
    tm.keyword_count DESC;
