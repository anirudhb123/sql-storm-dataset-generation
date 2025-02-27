WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank,
        COUNT(*) OVER (PARTITION BY at.id) AS total_actors
    FROM 
        aka_title at
    INNER JOIN 
        cast_info ci ON at.id = ci.movie_id
    INNER JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year IS NOT NULL AND
        ak.name IS NOT NULL
),

MoviesWithKeyword AS (
    SELECT 
        rm.title,
        rm.production_year,
        mk.keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.title = mk.movie_id
),

DistinctMovies AS (
    SELECT DISTINCT 
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        COUNT(mk.keyword) OVER (PARTITION BY m.title) AS keyword_count
    FROM 
        MoviesWithKeyword m
    LEFT JOIN 
        keyword k ON m.keyword = k.id
)

SELECT 
    id,
    title,
    production_year,
    keyword,
    keyword_count,
    (CASE
        WHEN keyword_count > 0 THEN 'Keyword Present'
        WHEN keyword_count IS NULL THEN 'No Keyword Info'
        ELSE 'No Keywords'
    END) AS keyword_status,
    (SELECT COUNT(DISTINCT ci.person_id)
     FROM cast_info ci
     WHERE ci.movie_id = DISTINCT_MOVIE.movie_id) AS total_distinct_actors
FROM 
    (SELECT ROW_NUMBER() OVER (ORDER BY production_year DESC) AS id, 
            title, 
            production_year, 
            keyword, 
            keyword_count
     FROM 
         DistinctMovies) AS DISTINCT_MOVIE
WHERE 
    production_year >= 2000 OR 
    (keyword_count = 0 AND FIND_IN_SET('Sci-Fi', keyword) > 0)
ORDER BY 
    production_year DESC, 
    keyword_count DESC
LIMIT 10;

### Explanation:
1. **CTEs (Common Table Expressions)** are used to structure the query logically:
   - `RankedMovies` ranks movies alongside the actors associated with them and counts the total number of actors.
   - `MoviesWithKeyword` collects movie and keyword data together with left joins.
   - `DistinctMovies` ensures uniqueness of titles while handling keywords.

2. **Window Functions** provide rankings and counts without the need for subqueries.

3. **Outer Joins** are utilized to maintain movie records even if they lack associated keywords or additional contexts.

4. **Complicated Predicates** check for distinct counts and keywords, applying theoretical logic to data presence in a quirky way.

5. **String Expressions** use `FIND_IN_SET` to demonstrate keyword filtering based on semantic conditions.

6. **Bizarre SQL Semantics:** 
   - Utilizing `COALESCE` to create a keyword column with a fallback.
   - Correlating actor counts per movie within a subquery based on the outer query context, showcasing correlated subqueries.

7. **Result Ordering and Limiting** control output to provide a manageable dataset for performance benchmarking.

This complex query is designed to test the database's ability to handle various SQL constructs and can showcase performance behavior under load due to interdependencies and subquery implementations.
