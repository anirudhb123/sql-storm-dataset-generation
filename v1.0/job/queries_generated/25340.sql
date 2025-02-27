WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.title = m.title
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    ak.name AS aka_name
FROM 
    TopMovies tm
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = tm.movie_id)
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC;
