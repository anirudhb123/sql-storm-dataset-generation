WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.*
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
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
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    tm.cast_count,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = tm.movie_id AND mc.company_type_id = 1) AS production_companies_count,
    (SELECT AVG(w.rating) FROM (
        SELECT 
            rt.movie_id,
            ROUND(AVG(r.rating), 2) AS rating
        FROM 
            ratings r  -- Assuming there is a ratings table
        JOIN 
            complete_cast cc ON cc.movie_id = rt.movie_id
        GROUP BY 
            rt.movie_id
    ) w WHERE w.movie_id = tm.movie_id) AS average_rating
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
