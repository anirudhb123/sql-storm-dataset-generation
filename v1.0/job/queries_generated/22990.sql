WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank_year
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY a.person_id
    HAVING COUNT(DISTINCT c.movie_id) > 10
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mkw
    JOIN keyword k ON mkw.keyword_id = k.id
    JOIN aka_title m ON mkw.movie_id = m.id
    WHERE k.keyword IS NOT NULL
    GROUP BY m.id
),
Companies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.country_code IS NOT NULL
    GROUP BY mc.movie_id
)
SELECT 
    r.title,
    r.production_year,
    ac.person_id,
    ac.movie_count,
    kw.keywords,
    co.companies,
    CASE 
        WHEN ac.movie_count > 20 THEN 'Prolific Actor'
        WHEN ac.movie_count BETWEEN 11 AND 20 THEN 'Frequent Actor'
        ELSE 'Occasional Actor'
    END AS actor_type,
    COALESCE(NULLIF(ac.movie_count, 0), 1) AS display_count
FROM RankedMovies r
LEFT JOIN ActorCounts ac ON r.title_id = ac.person_id
LEFT JOIN MoviesWithKeywords kw ON r.title_id = kw.movie_id
LEFT JOIN Companies co ON r.title_id = co.movie_id
WHERE 
    r.rank_year <= 5 
    AND (LOWER(kw.keywords) LIKE '%drama%' OR kw.keywords IS NULL)
ORDER BY 
    r.production_year DESC,
    ac.movie_count DESC
FETCH FIRST 10 ROWS ONLY;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - **RankedMovies**: Ranks movies by production year within each kind.
   - **ActorCounts**: Counts how many movies each actor has participated in, filtering those with more than 10.
   - **MoviesWithKeywords**: Aggregates keywords related to each movie using `STRING_AGG`.
   - **Companies**: Gathers associated companies, filtering out NULL country codes.

2. **Main Query**:
   - Selects relevant data with various left joins to pull in additional actor, keyword, and company information.
   - Uses a `CASE` statement to categorize actors based on their counts.
   - Employs `COALESCE` to handle potential NULL values in the count.

3. **Filtering and Ordering**:
   - Filters for top-ranked movies (latest 5) and checks for specific keywords.
   - Orders results to show the most recent productions with a cap of 10 results.

The query showcases an intricate use of multiple SQL constructs while ensuring edge cases are covered well with NULL handling and distinct aggregation.
