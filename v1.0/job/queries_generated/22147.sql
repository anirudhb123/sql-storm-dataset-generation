WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS row_num,
        COUNT(*) OVER (PARTITION BY m.production_year) AS total_movies
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
CastInfoWithRole AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.role_id) AS role_count,
        MAX(rt.role) AS highest_role,
        MIN(rt.role) AS lowest_role
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        SUM(mi.info IS NOT NULL) AS info_count,
        c.role_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY info_count DESC) AS info_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id
    LEFT JOIN 
        CastInfoWithRole c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, c.role_count
),
SelectedMovies AS (
    SELECT 
        movie_title,
        production_year,
        info_count,
        role_count,
        info_rank
    FROM 
        MovieDetails
    WHERE 
        info_count > 0 AND 
        role_count IS NOT NULL
)
SELECT 
    sm.movie_title,
    sm.production_year,
    sm.info_count,
    COALESCE(sm.role_count, 0) AS role_count,
    CASE 
        WHEN sm.info_rank <= 10 THEN 'Top 10'
        WHEN sm.info_rank BETWEEN 11 AND 20 THEN 'Top 20'
        ELSE 'Below Top 20'
    END AS ranking_category,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = (SELECT movie_id FROM SelectedMovies WHERE movie_title = sm.movie_title)) AS keywords
FROM 
    SelectedMovies sm
ORDER BY 
    sm.production_year DESC, sm.info_count DESC
LIMIT 50;

### Explanation:
1. **CTEs**:
   - `RankedMovies`: This CTE ranks movies by their title within their production year and counts the total number of movies released that year.
   - `CastInfoWithRole`: Aggregates cast information to get the count of roles per movie, along with the highest and lowest roles.
   - `MovieDetails`: Joins movie title with its information and cast roles while counting relevant info records.
   - `SelectedMovies`: Filters the results to include only movies with information and roles.

2. **Main Query**:
   - Retrieves movie title, production year, info count, role count, and a categorical ranking based on the info rank.
   - Uses a correlated subquery to gather keywords associated with each movie.

3. **Additional Logic**:
   - Incorporates `COALESCE` to ensure null values for role_count default to zero.
   - Includes a `CASE` statement for ranking categories.

4. **Sets and String Functions**:
   - Uses `STRING_AGG` for concatenating distinct keywords related to each movie.

This query showcases the use of complex SQL constructs while also handling NULL values, categorizing data, and performing aggregations effectively.
