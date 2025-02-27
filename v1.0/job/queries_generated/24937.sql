WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        STRING_AGG(keyword, ', ' ORDER BY keyword) AS keywords
    FROM 
        MoviesWithKeywords
    WHERE 
        rank_by_cast < 5 AND 
        production_year >= 2000
    GROUP BY 
        title, production_year, cast_count
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    NULLIF(tm.keywords, '') AS keywords,
    COALESCE((SELECT AVG(ci.nr_order) 
              FROM cast_info ci 
              WHERE ci.movie_id = (SELECT movie_id FROM MoviesWithKeywords m WHERE m.title = tm.title AND m.production_year = tm.production_year)), 0) AS average_cast_order
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
