
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
ExtendedMovieInfo AS (
    SELECT 
        r.*,
        kw.keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        MoviesWithKeywords kw ON r.movie_id = kw.movie_id
)
SELECT 
    e.movie_id, 
    e.title, 
    COALESCE(e.keywords, 'No keywords') AS keywords, 
    e.production_year, 
    e.cast_count, 
    CASE 
        WHEN e.rank_by_cast <= 3 THEN 'Top 3'
        ELSE 'Other'
    END AS rank_category
FROM 
    ExtendedMovieInfo e
WHERE 
    e.production_year >= 2000
ORDER BY 
    e.production_year DESC, e.cast_count DESC;
