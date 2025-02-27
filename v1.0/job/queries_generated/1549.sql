WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_per_year <= 5
),
MoviesWithKeywords AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year, tm.cast_count
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.cast_count,
    COALESCE(mwk.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(DISTINCT ci.person_id) FROM cast_info ci WHERE ci.movie_id IN 
        (SELECT id FROM aka_title WHERE production_year = mwk.production_year)) AS total_cast_count,
    CASE 
        WHEN mwk.cast_count > (SELECT AVG(cast_count) FROM TopMovies) THEN 'Above Average'
        WHEN mwk.cast_count < (SELECT AVG(cast_count) FROM TopMovies) THEN 'Below Average'
        ELSE 'Average'
    END AS cast_rating
FROM 
    MoviesWithKeywords mwk
ORDER BY 
    mwk.production_year DESC, mwk.cast_count DESC;
