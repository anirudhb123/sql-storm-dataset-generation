WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id, 
        a.title AS movie_title, 
        a.production_year, 
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON ci.movie_id = a.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.movie_title, 
        rm.production_year, 
        rm.total_cast,
        ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, rm.total_cast DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
)
SELECT 
    tm.rank, 
    tm.movie_title, 
    tm.production_year, 
    tm.total_cast, 
    tm.actor_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
