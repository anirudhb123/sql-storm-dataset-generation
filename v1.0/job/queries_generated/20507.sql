WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        rk.rank AS actor_rank,
        STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS actor_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title AS at
    LEFT JOIN 
        cast_info AS ci ON at.id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = at.id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        (SELECT 
            movie_id,
            RANK() OVER (PARTITION BY movie_id ORDER BY COUNT(*) DESC) AS rank
         FROM 
            cast_info 
         GROUP BY 
            movie_id) AS rk ON rk.movie_id = at.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year, rk.rank
    HAVING 
        COUNT(DISTINCT ak.person_id) > 3 
        AND SUM(CASE WHEN ak.name ILIKE '%Smith%' THEN 1 ELSE 0 END) > 0
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_rank,
    rm.actor_names,
    cd.company_names,
    CASE 
        WHEN cd.company_names IS NULL THEN 'Unknown Companies'
        ELSE cd.company_names
    END AS finalized_company_names,
    COALESCE(rm.company_count, 0) AS total_companies,
    CASE 
        WHEN rm.actor_rank IS NULL THEN 'No Rank'
        ELSE CAST(rm.actor_rank AS TEXT)
    END AS actor_rank_status
FROM 
    RankedMovies AS rm
FULL OUTER JOIN 
    CompanyDetails AS cd ON rm.movie_id = cd.movie_id
ORDER BY 
    rm.production_year DESC NULLS LAST, 
    rm.title ASC;

### Explanation:
1. **Common Table Expressions (CTEs)**: The query uses two CTEs:
   - `RankedMovies`: Ranks movies based on the count of distinct actors, filters for movies with more than three actors, and ensures that at least one actor's name contains 'Smith'.
   - `CompanyDetails`: Aggregates company names associated with each movie.

2. **Outer Join**: A `FULL OUTER JOIN` is used to combine the results of both CTEs, allowing retention of movies that do not have associated companies and vice versa.

3. **STRING_AGG with Filtering**: Uses `STRING_AGG` to concatenate actor names or company names, including a filter to exclude NULL values, showcasing SQL's ability to aggregate strings elegantly.

4. **HAVING and CASE Statements**: Implements complex predicates to filter results based on specific conditions. The `HAVING` clause enforces conditions post-aggregation, ensuring only relevant data is included.

5. **COALESCE and NULL Logic**: Uses `COALESCE` to handle potential NULL values, ensuring that values are provided even when no companies are found.

6. **Bizarre SQL Constructs**: Includes checks for actor names using the `ILIKE` operator (case-insensitive) and aggregates with conditions that result in unique SQL behavior, serving as a benchmark for the underlying database system's capabilities with respect to performance in handling large and complex queries.
