WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
MovieKeywords AS (
    SELECT 
        a.id AS movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.actor_count, 
        mk.keywords
    FROM 
        RankedMovies rm
    JOIN 
        MovieKeywords mk ON rm.title = mk.movie_id
    WHERE 
        rm.rank_per_year <= 5
)

SELECT 
    tm.title, 
    tm.production_year,
    COALESCE(tm.actor_count, 0) AS actor_count, 
    tm.keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.production_year = mi.info_type_id AND mi.info IS NOT NULL
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
