
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS akas,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.total_cast,
        rm.akas,
        KM.keyword AS movie_keyword,
        ROW_NUMBER() OVER (ORDER BY rm.total_cast DESC) AS movie_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword MK ON rm.movie_id = MK.movie_id
    LEFT JOIN 
        keyword KM ON KM.id = MK.keyword_id
    WHERE 
        rm.rank <= 5
)

SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.akas,
    LISTAGG(tm.movie_keyword, ', ') WITHIN GROUP (ORDER BY tm.movie_keyword) AS keywords
FROM 
    TopMovies tm
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, tm.total_cast, tm.akas
ORDER BY 
    tm.total_cast DESC;
