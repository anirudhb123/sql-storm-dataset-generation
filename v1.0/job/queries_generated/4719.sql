WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),

TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),

MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)

SELECT 
    t.movie_title,
    t.production_year,
    t.cast_count,
    COALESCE(k.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    TopMovies t
LEFT JOIN 
    MovieKeywords k ON t.movie_title = k.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.movie_id
GROUP BY 
    t.movie_title, t.production_year, t.cast_count, k.keywords
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    t.production_year DESC, t.cast_count DESC;
