WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT OUTER JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
HighlyRatedMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count 
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    HighlyRatedMovies m
LEFT JOIN 
    MovieKeywords mk ON m.movie_id = mk.movie_id
ORDER BY 
    m.production_year DESC,
    m.cast_count DESC;
