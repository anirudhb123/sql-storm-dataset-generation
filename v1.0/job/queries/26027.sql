
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    kt.kind AS movie_type
FROM 
    TopMovies AS tm
JOIN 
    kind_type AS kt ON tm.kind_id = kt.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
