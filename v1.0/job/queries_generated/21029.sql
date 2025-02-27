WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY a.id) AS avg_role_presence,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS movie_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE movie_rank <= 5
),
Directors AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT c.name || ' (' || co.name || ')') AS directors_info
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    JOIN 
        kind_type k ON mc.company_type_id = k.id
    JOIN 
        aka_name c ON c.id = mi.info_type_id 
    WHERE 
        k.kind = 'director'
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.avg_role_presence,
    d.directors_info,
    CASE 
        WHEN tm.total_cast IS NULL THEN 'Unknown'
        WHEN tm.total_cast > 5 THEN 'Ensemble'
        ELSE 'Limited'
    END AS cast_size_category
FROM 
    TopMovies tm
LEFT JOIN 
    Directors d ON tm.id = d.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC
LIMIT 10;

### Explanation:
1. **CTEs (Common Table Expressions)**:
    - `RankedMovies`: This CTE calculates the total distinct cast members for each movie, average role presence, and ranks them by total cast size within each production year.
    - `TopMovies`: It filters the `RankedMovies` to get only the top 5 movies with the most cast members per production year.
    - `Directors`: Joins multiple tables to extract directorial information along with the companies involved, ensuring it categorizes those companies as directors.

2. **Outer Joins**: The main query uses a LEFT JOIN to incorporate director information which may not exist for all movies.

3. **Window Functions**: `ROW_NUMBER()` is applied to rank movies based on cast size.

4. **String Expressions**: The `GROUP_CONCAT` function aggregates director names into a single string per movie, alongside company names.

5. **NULL Logic & Case Statements**: The `CASE` logic categorizes movies based on their cast size, handling NULL values appropriately to provide a default of ‘Unknown’.

6. **Ordering and Limiting**: The final selection orders results by production year (descending) and total cast size (descending) and limits the result set to the top 10 entries matching the criteria.

This query is a complex amalgamation of SQL constructs, embodying an architecture that tests performance through various joins, aggregations, and logical conditions across a multilayered relational schema.
