WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 10
),
MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        k.keyword
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keyword, 'No Keywords') AS keyword,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.movie_id
LEFT JOIN 
    complete_cast cc ON tm.title = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON tm.title = mc.movie_id
GROUP BY 
    tm.title, tm.production_year, mk.keyword, a.name
ORDER BY 
    tm.production_year DESC, 
    COUNT(DISTINCT mc.company_id) DESC;
