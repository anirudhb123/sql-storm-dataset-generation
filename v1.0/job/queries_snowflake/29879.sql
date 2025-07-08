WITH MovieDetails AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
        AND a.name NOT LIKE '%test%'
        AND t.title IS NOT NULL
    GROUP BY 
        a.id, a.name, t.title, t.production_year, t.kind_id
),

TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        kind_id,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        MovieDetails
)

SELECT 
    tm.movie_title,
    tm.production_year,
    k.kind AS movie_kind,
    tm.cast_count
FROM 
    TopMovies tm
JOIN 
    kind_type k ON tm.kind_id = k.id
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year DESC,
    tm.cast_count DESC;
