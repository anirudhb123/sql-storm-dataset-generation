WITH RECURSIVE MovieTree AS (
    SELECT 
        mt.movie_id,
        mt.linked_movie_id,
        1 AS depth
    FROM 
        movie_link mt
    WHERE 
        mt.link_type_id IN (SELECT id FROM link_type WHERE link = 'sequel')
    
    UNION ALL
    
    SELECT 
        mt.movie_id,
        mt.linked_movie_id,
        mt.depth + 1
    FROM 
        movie_link mt
    INNER JOIN 
        MovieTree mtree ON mt.movie_id = mtree.linked_movie_id
)
, CastWithRoles AS (
    SELECT 
        ai.person_id,
        ai.movie_id,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ai.person_id, ai.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        aka_name ai
    JOIN 
        cast_info ci ON ai.person_id = ci.person_id
)
, CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    t.title AS Movie_Title,
    t.production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS Actors,
    cm.company_names,
    cm.company_types,
    COUNT(DISTINCT mt.linked_movie_id) AS NumberOfSequels,
    AVG(role_order) AS AvgRoleOrder
FROM 
    title t
LEFT JOIN 
    MovieTree mt ON t.id = mt.movie_id
LEFT JOIN 
    CastWithRoles ak ON t.id = ak.movie_id
LEFT JOIN 
    CompanyMovieInfo cm ON t.id = cm.movie_id
WHERE 
    t.production_year IS NOT NULL
    AND (t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvseries')) OR t.id IS NULL)
GROUP BY 
    t.id, cm.company_names, cm.company_types
HAVING 
    COUNT(DISTINCT ak.person_id) > 2  -- Having more than 2 unique actors
    AND AVG(role_order) > 1  -- Only including movies where the average role order is greater than 1
ORDER BY 
    t.production_year DESC, 
    Movie_Title ASC;

### Explanation:
1. **CTEs**:
   - `MovieTree`: This recursively constructs a tree of movies that are sequels to earlier movies, keeping track of the depth in the hierarchy.
   - `CastWithRoles`: Gathers cast information along with their roles, assigning a row number to each role per person per movie.
   - `CompanyMovieInfo`: Aggregates company data associated with each movie, concatenating the names and types.

2. **Main Query**: 
   - Joins the title table with the CTEs such as `MovieTree`, `CastWithRoles`, and `CompanyMovieInfo`.
   - Uses `LEFT JOIN` for optional relationships, ensuring movies without sequels or companies still appear.
   - Adds predicates to filter for valid titles based on kind and year, including corner cases for nulls.
   - Implements grouping alongside aggregate functions like `COUNT` and `AVG` to derive meaningful insights about the movies.
   - The `HAVING` clause enforces conditions that require movies to feature a certain number of unique actors and average role orders, promoting a nuanced result set.

3. **Ordering**: Results are sorted by production year (latest first) and then title name alphabetically.
