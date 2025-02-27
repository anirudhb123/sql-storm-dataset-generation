WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        AVG(CASE WHEN c.note IS NULL THEN 0 ELSE 1 END) AS note_presence,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT
        title,
        production_year,
        cast_count 
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT AVG(note_presence) FROM RankedMovies) AS avg_note_presence,
    CASE
        WHEN AVG(tm.cast_count) OVER() > 10 THEN 'Popular'
        WHEN AVG(tm.cast_count) OVER() <= 0 THEN 'Unknown'
        ELSE 'Moderate'
    END AS popularity_category
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.movie_id
ORDER BY 
    tm.production_year DESC,
    tm.cast_count DESC;

-- Note: The query includes an outer join, a correlated subquery,
-- Common Table Expressions (CTEs), window functions, aggregate functions,
-- and conditional CASE expressions, presenting an elaborate performance benchmarking scenario.
