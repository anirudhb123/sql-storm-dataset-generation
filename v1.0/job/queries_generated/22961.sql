WITH RecursiveMovieCast AS (
    -- CTE to recursively find rich movie casting information
    SELECT ci.movie_id, ak.name AS actor_name, ci.nr_order,
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rnk
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE ci.nr_order IS NOT NULL

    UNION ALL

    SELECT mc.movie_id, 'Director' AS actor_name, NULL AS nr_order,
           ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY mc.company_id) AS rnk
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'Director'
),

FilteredMovies AS (
    -- CTE to filter movies that have a keyword of interest and are not marked with 'unknown'
    SELECT mt.movie_id, mt.title, mt.production_year,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM aka_title mt
    JOIN movie_keyword mk ON mt.id = mk.movie_id
    WHERE mk.keyword_id IS NOT NULL
      AND mt.title NOT LIKE '%unknown%'
    GROUP BY mt.movie_id, mt.title, mt.production_year
    HAVING COUNT(DISTINCT mk.keyword_id) > 2 -- Movies with more than 2 different keywords
),

NullCheck AS (
    -- CTE to handle potential NULL as a part of a more complex predicate
    SELECT movie_id, actor_name,
           CASE WHEN actor_name IS NULL THEN 'Unknown Actor' ELSE actor_name END AS display_name
    FROM RecursiveMovieCast
)

-- Final Selection with Outer Join to combine movie information and casting details
SELECT fm.title, fm.production_year, n.display_name,
       COALESCE(mk.keyword_count, 0) AS keyword_count,
       COUNT(n.display_name) OVER (PARTITION BY fm.movie_id) AS total_actors
FROM FilteredMovies fm
LEFT JOIN NullCheck n ON fm.movie_id = n.movie_id
LEFT JOIN movie_info mi ON fm.movie_id = mi.movie_id AND mi.info_type_id = 1 -- e.g., something like synopsis
WHERE fm.production_year IS NOT NULL
  AND (n.display_name IS NOT NULL OR n.display_name = 'Unknown Actor') -- Allow both known and unknown actors
ORDER BY fm.production_year DESC, keyword_count DESC, n.display_name;

### Explanation of the Query Components:
1. **CTE RecursiveMovieCast**: Recursively pulls all relevant actor and director names associated with each movie ID from the cast_info and movie_companies tables, sorted by `nr_order` or `company_id`.

2. **CTE FilteredMovies**: Filters movies based on a condition of having more than two unique keywords and excludes any titles that contain "unknown", ensuring we capture rich content.

3. **CTE NullCheck**: Ensures that in cases where actor names are NULL, a default label ("Unknown Actor") is provided for clarity.

4. **Final Selection and Outer Join**: Combines the filtered movie results with casting information, leveraging outer joins to ensure all relevant data is included while handling NULLs. The string expression ensures display of either known or defaulted actor names. Additionally, window functions provide counts of total actors per movie, enhancing the results analytics.

This query exemplifies complex query constructs while also illustrating nuanced handling of SQL corner cases such as NULL values and unusual title filtering.
