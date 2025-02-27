WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        company_count, 
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.company_count, 
    tm.keyword_count, 
    ak.name AS actor_name
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.title = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
ORDER BY 
    tm.production_year DESC, 
    tm.company_count DESC;
