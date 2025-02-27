WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(ci.person_id) OVER (PARTITION BY mt.id) AS cast_count,
        AVG(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year ELSE 0 END) OVER (PARTITION BY mt.kind_id) AS avg_year_by_kind
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NULL OR cn.country_code != 'NULL'
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        avg_year_by_kind
    FROM 
        RankedMovies
    WHERE 
        (production_year IS NOT NULL AND production_year > 1999) 
        OR (cast_count IS NOT NULL AND cast_count > 10)
),
ActorsWithMoreThanOneRole AS (
    SELECT 
        person_id,
        COUNT(DISTINCT role_id) AS role_count
    FROM 
        cast_info
    GROUP BY 
        person_id
    HAVING 
        COUNT(DISTINCT role_id) > 1
)
SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    f.avg_year_by_kind,
    ak.name AS actor_name,
    r.role AS role_type
FROM 
    FilteredMovies f
INNER JOIN 
    cast_info ci ON f.movie_id = ci.movie_id
INNER JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name NOT LIKE '%unknown%'
    AND r.role IS NOT NULL -- Not considering roles that are null
    AND EXISTS (SELECT 1 
                FROM ActorsWithMoreThanOneRole ar
                WHERE ar.person_id = ci.person_id)
ORDER BY 
    f.production_year DESC,
    f.cast_count DESC,
    ak.name;

This SQL query does the following:

1. **Common Table Expressions (CTEs)**: 
   - `RankedMovies` generates a base set of movies ranked by the number of cast members while also calculating the average production year per kind.
   - `FilteredMovies` filters these movies based on production year and cast count criteria.
   - `ActorsWithMoreThanOneRole` retrieves actors who have played more than one role.

2. **Joins**: 
   - The main query joins the filtered movies with the `cast_info`, `aka_name`, and `role_type` tables to get details about actors and their roles.

3. **Filtering**: 
   - Conditions are applied to exclude actors whose names include 'unknown' and ensure only recognized roles are included.

4. **Aggregation and Window Functions**: Using `COUNT` and `AVG` in conjunction with `OVER` for window functions to facilitate complex ranking and aggregations.

5. **NULL Logic**: The query handles NULL cases specifically, ensuring robust handling of those records in all relevant tables.

6. **Sorting**: The results are then sorted by year and cast count, ensuring the most relevant and enriched data is easily accessible.

This query showcases an advanced SQL querying technique using various constructs for performance benchmarking and serves as a solid example for testing database performance.
