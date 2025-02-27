WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT c.person_id) AS cast_count,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    cast_info c ON tm.movie_id = c.movie_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, mk.keywords
ORDER BY 
    tm.production_year DESC, cast_count DESC;
