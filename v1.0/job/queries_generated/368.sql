WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMoviesByYear AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(k.keywords, 'No keywords') AS keywords,
    m.actor_count
FROM 
    TopMoviesByYear m
LEFT JOIN 
    MovieKeywords k ON m.title = k.movie_id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC, 
    m.actor_count DESC;
