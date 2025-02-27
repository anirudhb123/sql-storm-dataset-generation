WITH RankedMovies AS (
    SELECT 
        a.title,
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
        title, 
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
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS all_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COALESCE(mi.all_info, 'No additional info') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = (SELECT title FROM aka_title WHERE id IN (SELECT movie_id FROM movie_info WHERE movie_id IS NOT NULL AND title = tm.title LIMIT 1))
LEFT JOIN 
    MovieInfo mi ON LOWER(tm.title) LIKE '%' || LOWER(mi.title) || '%'
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;

-- Additional Explanation:
-- This query finds the top 5 movies from each production year based on the number of unique cast members.
-- It joins these results with keyword counts and additional movie information.
-- It utilizes CTEs, LEFT JOINs, and COALESCE to handle possible NULL values in a coherent manner.
-- Furthermore, it uses window functions to rank movies and STRING_AGG for aggregation of related information.
