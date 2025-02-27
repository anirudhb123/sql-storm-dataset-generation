WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, LENGTH(a.title)) AS rank_per_year
    FROM aka_title a
    WHERE a.production_year IS NOT NULL
),
MovieActors AS (
    SELECT 
        m.title,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT ak.person_id) AS actor_count
    FROM aka_title m
    JOIN cast_info ci ON m.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY m.title
),
KeywordMovies AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title m ON mk.movie_id = m.id
    GROUP BY m.id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(MAX(mi.info), 'No Info') AS info_summary
    FROM aka_title m
    LEFT JOIN movie_info mi ON mi.movie_id = m.id
    GROUP BY m.id
)
SELECT 
    rm.title,
    rm.production_year,
    ma.actors,
    ma.actor_count,
    km.keywords,
    mi.info_summary
FROM RankedMovies rm
LEFT JOIN MovieActors ma ON rm.title = ma.title
LEFT JOIN KeywordMovies km ON rm.rank_per_year = km.movie_id
LEFT JOIN MovieInfo mi ON rm.production_year = mi.movie_id
WHERE rm.rank_per_year <= 5 -- Top 5 movies per production year
AND (ma.actor_count > 1 OR mi.info_summary IS NOT NULL)
ORDER BY rm.production_year DESC, ma.actor_count DESC, rm.title;

### Explanation of Query Constructs:
- **Common Table Expressions (CTEs):**
  - `RankedMovies`: Assigns a rank based on the production year, filtering out NULL years and ordering by title length.
  - `MovieActors`: Aggregates actor names for each movie using `STRING_AGG`, counting distinct actors.
  - `KeywordMovies`: Aggregates keywords associated with each movie and groups them.
  - `MovieInfo`: Gathers the most relevant (or a fallback) info per movie using `COALESCE` to handle NULLs.

- **Joining and Filtering Logic:**
  - The final SELECT combines the results of all CTEs through LEFT JOINs, enabling the inclusion of movies with missing actors or keywords.
  - The use of filtering conditions (`AND (ma.actor_count > 1 OR mi.info_summary IS NOT NULL)`) illustrates complex logic with the OR condition possibly handling NULLs.

- **Window Functions:**
  - `ROW_NUMBER()` defines a ranking method that delivers results suited for benchmarking.

- **Bizarre Semantics:**
  - Employing `COALESCE()` in the `MovieInfo` CTE to provide default values systematically captures edge cases.
  - Managing an outer join scenario allows for an inclusive dataset that handles missing relationships across multiple CTEs.

- **String Expressions:**
  - The `STRING_AGG()` function is used to provide an aggregated view of respective actors and keywords, highlighting SQL’s capabilities with string manipulations.

This intricate query showcases advanced SQL functionalities while considering various edge cases related to NULL handling, join types, and aggregation methods.
