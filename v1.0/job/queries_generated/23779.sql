WITH RecursiveTitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CastStatistics AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(CASE WHEN c.role_id IS NOT NULL THEN 1 END) AS roles_count,
        AVG(COALESCE(cs.kind, 0)) AS avg_role_type
    FROM 
        cast_info c
    LEFT JOIN 
        comp_cast_type cs ON c.person_role_id = cs.id
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT cn.country_code) AS num_countries
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
KeywordRankings AS (
    SELECT 
        keyword,
        DENSE_RANK() OVER (ORDER BY COUNT(movie_id) DESC) AS rank
    FROM 
        movie_keyword
    GROUP BY 
        keyword
),
FinalResults AS (
    SELECT 
        ti.title_id,
        ti.title,
        ti.production_year,
        ti.keyword,
        cs.total_cast,
        cs.roles_count,
        co.company_names,
        co.num_countries,
        kr.rank AS keyword_rank
    FROM 
        RecursiveTitleInfo ti
    JOIN 
        CastStatistics cs ON ti.title_id = cs.movie_id
    JOIN 
        CompanyDetails co ON ti.title_id = co.movie_id
    LEFT JOIN 
        KeywordRankings kr ON ti.keyword = kr.keyword
    WHERE 
        ti.year_rank <= 3
        AND (cs.total_cast > 5 OR co.num_countries > 1)
)
SELECT 
    *,
    CASE 
        WHEN keyword_rank IS NULL THEN 'Unranked'
        ELSE CAST(keyword_rank AS TEXT)
    END AS keyword_rank_status,
    COALESCE(total_cast, 'N/A') AS cast_status
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    title;

This SQL query provides a performance benchmarking scenario by combining multiple constructs:

1. **Common Table Expressions (CTEs)**: 
   - `RecursiveTitleInfo` collects title information along with keywords and ranks titles by production year.
   - `CastStatistics` aggregates data on the cast of each movie, counting distinct persons and average role types.
   - `CompanyDetails` compiles company information associated with movies, aggregating company names and counting different countries.
   - `KeywordRankings` ranks keywords based on their movie associations.

2. **Outer Joins**: Utilizing `LEFT JOIN` to include records even if there are no associated records (e.g., no keywords).

3. **Window Functions**: Use of `ROW_NUMBER()` for ranking titles and `DENSE_RANK()` for ranking keywords.

4. **COALESCE**: Used to provide default values (e.g., replace `NULL` with 'No Keyword').

5. **STRING_AGG**: To concatenate company names into a single string.

6. **Complex WHERE Clauses**: Filtering results based on specific predicates involving counts and ranks, showcasing complexity.

7. **NULL Logic**: Conditional handling of potentially NULL values in the final selection list.

8. **Final Output Formatting**: The final SELECT statement includes computed columns to handle cases when a movie might not be ranked or have a cast status of not available.

This query exemplifies various SQL constructs and logic while remaining grounded within real analysis and reporting scenarios.
