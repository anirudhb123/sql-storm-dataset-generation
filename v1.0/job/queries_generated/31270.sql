WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(COUNT(ci.id) AS INTEGER) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.cast_count + 1
    FROM 
        MovieCTE m
    JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    WHERE 
        m.cast_count < 10
),
LatestMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        lm.movie_id,
        lm.title,
        lm.production_year
    FROM 
        LatestMovies lm
    WHERE 
        lm.rn <= 5
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    t.title AS movie_title,
    t.production_year,
    ci.person_role_id,
    COUNT(ci.person_role_id) AS role_count,
    ki.keywords,
    COUNT(DISTINCT c.id) AS unique_cast
FROM 
    TopMovies t
LEFT JOIN 
    cast_info ci ON t.movie_id = ci.movie_id
LEFT JOIN 
    KeywordInfo ki ON t.movie_id = ki.movie_id
LEFT JOIN 
    company_name cn ON t.movie_id = cn.imdb_id  -- Assuming company_name is linked via imdb_id
LEFT JOIN 
    complete_cast cc ON t.movie_id = cc.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id 
WHERE 
    t.production_year >= 2000
    AND (cn.country_code IS NOT NULL OR cn.id IS NOT NULL)  -- Filter for non-empty country codes or company IDs
GROUP BY 
    t.title, 
    t.production_year,
    ci.person_role_id,
    ki.keywords
HAVING 
    COUNT(ci.person_role_id) > 2
ORDER BY 
    t.production_year DESC, 
    role_count DESC;

This SQL query takes advantage of several advanced SQL features:

1. **Common Table Expressions (CTEs)**: Recursive CTE `MovieCTE` to aggregate movie casts, `LatestMovies` to capture the latest movies per year, and `KeywordInfo` to aggregate keywords associated with movies.
  
2. **LEFT JOINs**: To retrieve data from multiple tables while including all records from the `TopMovies`.

3. **String Aggregation**: Using `STRING_AGG` to concatenate keywords into a single string.

4. **Window Functions**: `ROW_NUMBER()` is utilized to rank the movies by production year.

5. **Complex Predicates**: Filters based on conditions involving NULL checks and logical OR operators.

6. **Group By and Having**: Aggregates data based on roles and ensures that only movies with more than 2 roles are included in the final results.

This query aims to give insight into movies produced after 2000, including their title, production year, and involvement of various cast members while demonstrating performance through distinct role counts and keywords.
