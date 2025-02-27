WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT c.role_id ORDER BY c.nr_order) AS role_ids,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        aka_name ak ON ak.person_id = mc.company_id
    LEFT JOIN 
        cast_info c ON c.movie_id = mt.id
    GROUP BY 
        mt.id
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        aka_names,
        role_ids,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.aka_names,
    tm.cast_count,
    rt.role AS role_type
FROM 
    TopMovies tm
JOIN 
    role_type rt ON rt.id = ANY(tm.role_ids)
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC, 
    tm.production_year DESC;

This SQL query benchmarks string processing by first aggregating movie titles with their corresponding alternate names (aka_names) and roles in the `RankedMovies` Common Table Expression (CTE). It ranks movies by the count of distinct cast members and then selects the top 10 movies from the second CTE `TopMovies`, joining with the `role_type` table to include role types. The results are ordered by the cast count and production year, allowing for a clear comparison of top films with significant cast details.
