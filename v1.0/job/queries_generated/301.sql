WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
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
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    JOIN 
        aka_title t ON tm.title = t.title AND tm.production_year = t.production_year
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, tm.production_year
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id LIMIT 1)
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title 
GROUP BY 
    tm.title, tm.production_year, mk.keywords
ORDER BY 
    tm.production_year DESC, company_count DESC;
