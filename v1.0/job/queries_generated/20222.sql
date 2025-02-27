WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5  -- Top 5 movies by cast count per production year
),

CompanyMovieInfo AS (
    SELECT 
        mm.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        STRING_AGG(DISTINCT mi.info) AS movie_info,
        STRING_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_companies mm
    JOIN 
        company_name cn ON mm.company_id = cn.id
    JOIN 
        movie_info mi ON mm.movie_id = mi.movie_id
    JOIN 
        movie_keyword mk ON mm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mm.movie_id
)

SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    cmi.companies,
    cmi.movie_info,
    cmi.keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    CompanyMovieInfo cmi ON fm.movie_id = cmi.movie_id
ORDER BY 
    fm.production_year, fm.cast_count DESC;

-- Including a subquery as an inline filter for titles containing 'The' but excluding those from 2025
WHERE 
    fm.title LIKE '%The%' AND
    fm.production_year <> 2025;

-- Additionally performing a LEFT JOIN on character names to gather allied roles and avoid NULL outcomes
LEFT JOIN (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT cn.name || ' as ' || rt.role, ', ') AS roles
    FROM 
        cast_info ci
        JOIN role_type rt ON ci.role_id = rt.id
        JOIN char_name cn ON ci.person_id = cn.imdb_id 
    GROUP BY 
        ci.movie_id
) AS RankedRoles ON fm.movie_id = RankedRoles.movie_id;

### Explanation:

1. **CTEs (Common Table Expressions)**:
   - The first CTE (`RankedMovies`) ranks movies within their production year based on the count of cast members.
   - The second CTE (`FilteredMovies`) selects the top 5 movies for each production year.
   - The third CTE (`CompanyMovieInfo`) aggregates movie companies, additional movie info, and keywords for corresponding movies.

2. **Main Query**:
   - Joins the `FilteredMovies` CTE with `CompanyMovieInfo` to display detailed information about the movies while fulfilling certain conditions, such as filtering titles that contain the word “The” and excluding production year 2025.

3. **LEFT JOIN for Roles**:
   - This subquery gathers all character names and their associated roles to provide comprehensive role details while ensuring that even if characters are not found, the movie details are still returned.

4. **Complex String Functions**:
   - Used `GROUP_CONCAT`/`STRING_AGG` to concatenate names and related info.

5. **NULL Logic**: 
   - Managed through LEFT JOINs, ensuring results are still returned even when certain elements (like companies or roles) are absent.

This query is structured to encapsulate a variety of SQL features and handle edge semantical cases while delivering a rich dataset for performance comparison.
