WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        at.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_per_year,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_per_year
    FROM aka_title at
    WHERE at.kind_id IN (
        SELECT id FROM kind_type WHERE kind LIKE '%Feature%'
    )
),
FullCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ak.person_id,
        ci.person_role_id,
        ci.nr_order,
        CTE.rank_per_year,
        CTE.total_per_year
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN RankedMovies CTE ON ci.movie_id = CTE.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(CAST(SUM(mk.keyword) AS VARCHAR), 'No Keywords') AS movie_keywords,
        COALESCE(GROUP_CONCAT(DISTINCT nm.name ORDER BY nm.name), 'No Actors') AS actor_list,
        COUNT(DISTINCT MK.movie_id) AS keyword_count,
        COUNT(DISTINCT FC.actor_name) AS unique_actor_count
    FROM aka_title m
    LEFT JOIN movie_keyword MK ON m.id = MK.movie_id
    LEFT JOIN FullCast FC ON m.id = FC.movie_id
    JOIN name nm ON FC.person_id = nm.id
    GROUP BY m.movie_id, m.title
),
FinalOutput AS (
    SELECT 
        md.movie_id,
        md.title,
        md.movie_keywords,
        md.actor_list,
        md.keyword_count,
        md.unique_actor_count,
        CASE 
            WHEN md.keyword_count IS NULL THEN 'No keywords found'
            WHEN md.unique_actor_count = 0 THEN 'No actors listed'
            ELSE 'Data available'
        END AS status
    FROM MovieDetails md
    WHERE md.movie_id IN (
        SELECT movie_id FROM complete_cast WHERE status_id = (
            SELECT id FROM info_type WHERE info = 'Released'
        )
    )
)
SELECT 
    fo.title,
    fo.movie_keywords,
    fo.actor_list,
    fo.keyword_count,
    fo.unique_actor_count,
    fo.status,
    COALESCE((SELECT AVG(total_per_year) FROM RankedMovies), 0) AS avg_total_per_year,
    CASE 
        WHEN fo.keyword_count > 5 THEN 'Highly Tagged'
        WHEN fo.actor_list IS NULL THEN 'Actor List Missing'
        ELSE 'Average Movie'
    END AS movie_classification
FROM FinalOutput fo
ORDER BY fo.keyword_count DESC, fo.unique_actor_count ASC, fo.title;

### Explanation:
1. **CTEs**:
   - **`RankedMovies`**: This CTE ranks movies by production year and counts total movies per year.
   - **`FullCast`**: Joins the cast info and actor names, along with the ranking from `RankedMovies`.
   - **`MovieDetails`**: Gathers details about movies, keywords, and actors, handling NULL cases with `COALESCE`.
   - **`FinalOutput`**: Filters movies based on their release status and organizes the final output.

2. **Subqueries**:
   - Used to pull only released movies from a specific table and to indirectly calculate average rankings.

3. **Window Functions**:
   - `ROW_NUMBER()` is used to rank movies by year.
   - `COUNT()` over partition helps in getting total counts.

4. **Outer Joins**:
   - Several left joins are used to handle cases where no keywords or actors are present, ensuring that movies without such data are still included.

5. **NULL Logic**:
   - Handled via `COALESCE` and conditional checks in the final output.

Overall, this query presents an intricate landscape combining inner and outer joins, CTEs, aggregates, and conditional logic, making it suitable for performance benchmarking and analysis.
