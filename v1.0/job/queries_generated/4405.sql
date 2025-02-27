WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    GROUP BY 
        a.title, a.production_year
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        mk.movie_id
), 
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.cast_count, 
        mk.keywords 
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = rm.production_year
    WHERE 
        rm.rank_per_year <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    COALESCE(tm.keywords, 'No keywords') AS keywords, 
    (SELECT AVG(pi.info) 
     FROM person_info pi 
     WHERE EXISTS (SELECT 1 
                   FROM cast_info ci 
                   WHERE ci.movie_id IN (SELECT movie_id 
                                          FROM aka_title WHERE title = tm.title))
     AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) AS average_rating
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
