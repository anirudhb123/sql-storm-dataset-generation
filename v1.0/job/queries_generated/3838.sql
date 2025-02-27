WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        SUM(CASE WHEN ak.surname_pcode IS NULL THEN 1 ELSE 0 END) AS null_surnames
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year > 2000
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        actors,
        null_surnames,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.actors,
    COALESCE(NULLIF(tm.null_surnames, 0), 'No Null Surnames') AS surname_info
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
