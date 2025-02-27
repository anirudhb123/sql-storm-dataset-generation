WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(cast.id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title mt ON ak.movie_id = mt.id
    LEFT JOIN 
        cast_info cast ON mt.id = cast.movie_id
    GROUP BY 
        mt.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    string_agg(DISTINCT akn.name, ', ') AS associated_names,
    jsonb_agg(DISTINCT jsonb_build_object('name', cn.name, 'type', ct.kind)) AS companies
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    aka_name akn ON akn.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = tm.movie_id)
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.cast_count DESC;
