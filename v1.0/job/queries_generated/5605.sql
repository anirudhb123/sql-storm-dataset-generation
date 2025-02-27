WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword) AS total_keywords
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
), 
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.total_cast,
        rm.total_keywords,
        RANK() OVER (ORDER BY rm.total_cast DESC, rm.total_keywords DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.total_keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.total_cast DESC, 
    tm.movie_title ASC;
