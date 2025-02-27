WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS movie_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
        AND t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MAX(role.role) AS primary_role
    FROM 
        cast_info ci
    JOIN 
        role_type role ON ci.role_id = role.id
    GROUP BY 
        ci.movie_id
),
MoviesWithCompany AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mb.cast_count, 0) AS total_cast,
    COALESCE(mc.company_names, 'No Companies') AS production_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mb ON rm.movie_id = mb.movie_id
LEFT JOIN 
    MoviesWithCompany mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.movie_rank <= 5
    AND (mb.cast_count IS NULL OR mb.cast_count > 2)
    OR rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year DESC,
    rm.title;

This SQL query is designed to extract interesting insights from the provided schema. It includes:

1. **Common Table Expressions (CTEs)**: Used to structure the query into readable parts, focusing on ranked movies, cast counts, and associated production companies.
2. **Window Functions**: The `ROW_NUMBER()` function ranks movies by their ID within each production year.
3. **Aggregate Functions**: `COUNT(DISTINCT)` counts unique cast members, and `GROUP_CONCAT` aggregates company names associated with each movie.
4. **LEFT Joins**: Allow for capturing movies even when they might not have associated cast or companies.
5. **Complex WHERE Conditions**: Filters based on rank and cast counts, allowing for a nuanced selection of records.
6. **Order by Semantics**: Results are ordered by production year and title to enhance readability of the output.

This query is a good representation of a complex SQL statement utilizing various constructs to meet specific business logic while showcasing intricate SQL capabilities.
