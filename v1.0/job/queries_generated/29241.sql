WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT a.name) AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        cast_names,
        keywords,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year BETWEEN 2000 AND 2020
)
SELECT 
    tm.rank,
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
