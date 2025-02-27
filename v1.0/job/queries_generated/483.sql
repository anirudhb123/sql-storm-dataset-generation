WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (ORDER BY a.production_year DESC, COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(mi.info, ', ') AS keywords
    FROM 
        movie_info mi
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    GROUP BY 
        m.movie_id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mi.keywords, 'No keywords available') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieInfo mi ON rm.title = mi.movie_id
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.keywords,
    CASE 
        WHEN tm.production_year IS NULL THEN 'Unknown Year'
        WHEN tm.cast_count IS NULL THEN 'No Cast'
        ELSE 'Available Info' 
    END AS info_status
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
