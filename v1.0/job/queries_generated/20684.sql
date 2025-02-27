WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL 
        AND t.production_year > 2000
),
FilteredCast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        c.nr_order,
        r.role,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    fc.person_id,
    fc.role,
    COALESCE(mkw.keywords, 'No keywords') AS keywords,
    fc.nr_order,
    fc.total_cast_count,
    CASE 
        WHEN fc.total_cast_count > 5 THEN 'Large Cast'
        WHEN fc.total_cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size,
    EXISTS (
        SELECT 
            1 
        FROM 
            person_info pi 
        WHERE 
            pi.person_id = fc.person_id 
            AND pi.info_type_id = (
                SELECT id FROM info_type WHERE info = 'Birthdate' LIMIT 1
            )
            AND pi.info IS NOT NULL
    ) AS has_birthdate_info
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCast fc ON rm.movie_id = fc.movie_id
LEFT JOIN 
    MoviesWithKeywords mkw ON rm.movie_id = mkw.movie_id
WHERE 
    (fc.nr_order < 3 OR fc.nr_order IS NULL) 
    AND rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    cast_size DESC;

This SQL query does the following:

1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: Retrieves movies produced after 2000 and ranks them by ID within each production year.
   - `FilteredCast`: Filters cast info to include only those with a valid `nr_order` and calculates the total number of cast members for each movie.
   - `MoviesWithKeywords`: Aggregates keywords associated with each movie.

2. **Main Query**:
   - Combines data from all three CTEs, using various join types (specifically a left join for optional data).
   - Utilizes the `COALESCE` function to handle NULL keywords.
   - Applies conditional logic through `CASE` to categorize the size of the cast.
   - Checks for the existence of birthdate info in another table using a correlated subquery.

3. **Filters and Order**:
   - Incorporates complicated predicates with conditions on `nr_order` and a limit on ranks.
   - Sorts final results based on production year and cast size.

This query intricately combines multiple SQL features and constructs to form a comprehensive and efficient benchmarking query for the provided schema.
