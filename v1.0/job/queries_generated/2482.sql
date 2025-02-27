WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
), 
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 5
), 
MovieKeywords AS (
    SELECT 
        m.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
)
SELECT 
    t.title, 
    t.production_year, 
    COALESCE(k.keywords, ARRAY[]::text[]) AS keywords
FROM 
    TopMovies t
LEFT JOIN 
    MovieKeywords k ON t.title = k.title
ORDER BY 
    t.production_year DESC, 
    t.title;
