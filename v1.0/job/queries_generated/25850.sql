WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000  -- Focus on movies from 2000 onwards
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count,
        cast_names,
        RANK() OVER (ORDER BY cast_count DESC, production_year ASC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    COALESCE(mk.keyword, 'No Keywords') AS keywords,
    COALESCE(mi.info, 'No Info') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.title_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON tm.title_id = mi.movie_id
WHERE 
    tm.rank <= 10  -- Limit to top 10 movies based on cast count
ORDER BY 
    tm.rank;
