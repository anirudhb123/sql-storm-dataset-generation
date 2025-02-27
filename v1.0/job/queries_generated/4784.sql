WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
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
    tm.movie_title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    tm.actor_count,
    CASE 
        WHEN tm.actor_count > 10 THEN 'Ensemble Cast'
        WHEN tm.actor_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Few Actors'
    END AS cast_size_description
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_title = mi.info
LEFT JOIN 
    MovieKeywords mk ON mi.movie_id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
