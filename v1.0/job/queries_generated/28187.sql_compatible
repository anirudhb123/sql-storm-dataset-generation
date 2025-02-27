
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
HighCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actor_names
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        HighCastMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    hc.movie_id,
    hc.title,
    hc.production_year,
    hc.cast_count,
    mk.keywords
FROM 
    HighCastMovies hc
LEFT JOIN 
    MovieKeywords mk ON hc.movie_id = mk.movie_id
ORDER BY 
    hc.production_year DESC, 
    hc.cast_count DESC;
