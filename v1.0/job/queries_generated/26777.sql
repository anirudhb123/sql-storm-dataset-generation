WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(a.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    k.keyword,
    ci.kind AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ci ON mc.company_type_id = ci.id
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;

This SQL query benchmarks string processing by aggregating casting information from various related tables and providing a refined output of the top 5 movies by cast size for each production year, along with associated keywords and company types. The use of common table expressions (CTEs) and string aggregation functions demonstrates complex string manipulations, thereby illustrating performance in string processing scenarios.
