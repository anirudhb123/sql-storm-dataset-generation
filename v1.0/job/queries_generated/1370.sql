WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
Keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(kw.keyword_list, 'No keywords') AS keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = tm.movie_id AND cc.status_id IS NULL) AS unconfirmed_cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    Keywords kw ON tm.movie_id = kw.movie_id
WHERE 
    tm.cast_count > 3 
    AND tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
