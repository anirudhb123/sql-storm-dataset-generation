WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
ComplexMovieData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cr.role, 'Unknown') AS role,
        cr.role_count,
        CASE 
            WHEN rm.rank = 1 THEN 'Top'
            ELSE 'Other'
        END AS rank_category,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = rm.movie_id) AS keyword_count,
        (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
         FROM movie_companies mc 
         JOIN company_name cn ON mc.company_id = cn.id 
         WHERE mc.movie_id = rm.movie_id) AS production_companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastRoles cr ON rm.movie_id = cr.movie_id
)
SELECT 
    cmd.title,
    cmd.production_year,
    cmd.role,
    cmd.role_count,
    cmd.rank_category,
    cmd.keyword_count,
    cmd.production_companies,
    CASE 
        WHEN cmd.production_year < 2000 THEN 'Classic'
        WHEN cmd.production_year BETWEEN 2000 AND 2010 THEN 'Modern Classic'
        ELSE 'Recent'
    END AS era,
    (SELECT AVG(word_length) 
     FROM (SELECT LENGTH(word) AS word_length 
           FROM unnest(string_to_array(cmd.title, ' ')) AS word) AS lengths) AS avg_word_length,
    CASE 
        WHEN cmd.role_count IS NULL THEN 'No Roles Detected'
        ELSE 'Roles Detected'
    END AS role_status
FROM 
    ComplexMovieData cmd
WHERE 
    cmd.production_year IS NOT NULL
ORDER BY 
    cmd.production_year DESC, 
    cmd.title
LIMIT 100;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - **RankedMovies**: Ranks movies by year and title, filtering null production years.
   - **CastRoles**: Aggregates roles by movie, counting role occurrences.
   - **ComplexMovieData**: Combines data from RankedMovies and CastRoles, adds additional calculations, such as keyword counts and company names.

2. **LEFT JOIN**: Used in `ComplexMovieData` to link movies with cast roles, handling cases where a movie may have no roles.

3. **Subqueries**: 
   - One subquery counts keywords per movie.
   - Another subquery aggregates unique production company names into a comma-separated string.

4. **CASE Statements**: Used for complex categorization based on thresholds of years and counts.

5. **Window Functions**: `ROW_NUMBER` is used to rank the movies per year.

6. **String Expressions**: The title is split into words to calculate average word length.

7. **NULL Logic**: The query checks for NULL roles, providing a response on whether roles were detected.

8. **Ordering and Limiting**: Final selection sorts results by production year and then title, limiting to the top 100 results. 

This query intricately binds various SQL concepts together, showcasing the power and flexibility of SQL in data management and analysis.
