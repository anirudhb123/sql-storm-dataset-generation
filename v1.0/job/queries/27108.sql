
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        cast_names,
        keywords,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    tm.keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10 
ORDER BY 
    tm.rank;
