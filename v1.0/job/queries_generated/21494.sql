WITH Recursive CastHierarchy AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.nr_order,
        1 AS depth
    FROM cast_info ci
    WHERE ci.nr_order IS NOT NULL
    UNION ALL
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.nr_order,
        ch.depth + 1
    FROM cast_info ci
    JOIN CastHierarchy ch ON ci.movie_id = ch.movie_id 
    WHERE ci.person_id <> ch.person_id AND ci.nr_order IS NOT NULL
),
CombinedTitles AS (
    SELECT 
        t.title AS movie_title,
        aka.name AS aka_name,
        t.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM aka_title aka
    JOIN title t ON aka.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
RankedMovies AS (
    SELECT 
        ct.movie_id,
        ct.movie_title,
        ct.aka_name,
        ct.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY ct.movie_id) AS total_cast,
        RANK() OVER (ORDER BY ct.production_year DESC) AS year_rank
    FROM CombinedTitles ct
    LEFT JOIN cast_info ci ON ci.movie_id = ct.movie_id
)
SELECT 
    rm.movie_title,
    rm.aka_name,
    rm.production_year,
    COALESCE(CH.depth, 0) AS cast_depth,
    rm.total_cast,
    CASE 
        WHEN rm.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(rm.year_rank AS TEXT)
    END AS ranked_year,
    STRING_AGG(DISTINCT ci.note, ', ') FILTER (WHERE ci.note IS NOT NULL) AS cast_notes
FROM RankedMovies rm
LEFT JOIN cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN CastHierarchy CH ON rm.movie_id = CH.movie_id
WHERE rm.total_cast > 0
GROUP BY rm.movie_id, rm.movie_title, rm.aka_name, rm.production_year
ORDER BY rm.production_year DESC, cast_depth DESC, movie_title ASC
LIMIT 50;

### Explanation:
- **CTEs (Common Table Expressions)**: 
  - `CastHierarchy`: recursively grabs the hierarchy of cast members per movie and calculates the depth.
  - `CombinedTitles`: combines movie titles with known aliases and associated keywords.
  - `RankedMovies`: calculates the total number of cast members per movie and assigns a ranking based on the production year.
  
- **Outer Joins and Aggregation**: 
  - Uses left joins to gather all relevant data while ensuring no loss of information and subsequently aggregates cast notes.
  
- **NULL Logic**: 
  - Handles scenarios where production years or notes might be NULL, providing defaults or alternative outputs.

- **Window Functions**: 
  - Employed to rank movies and count distinct cast members dynamically.

- **Bizarre Logic**: 
  - Handles cases where it counts cast members but ensures it omits movies with zero participants in the final result.
  
- **String Expressions**: 
  - Aggregates cast notes into a single-string format.

This SQL query showcases a complex combination of SQL features, including recursive CTEs, window functions, aggregation, detailed subquery logic, and robust handling of NULL values.
