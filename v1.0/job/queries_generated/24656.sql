WITH RecursiveTitles AS (
    SELECT t.id, t.title, t.production_year, t.kind_id, 
           ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS recent_rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
ExtendedCast AS (
    SELECT ci.id, ci.movie_id, ci.person_id, 
           COALESCE(an.name, 'Unknown') AS actor_name, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order,
           COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) OVER (PARTITION BY ci.movie_id) AS role_count
    FROM cast_info ci
    LEFT JOIN aka_name an ON ci.person_id = an.person_id
),
FilteredMovies AS (
    SELECT mt.*, 
           COUNT(mk.keyword_id) AS keyword_count,
           AVG(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mt.id) AS info_ratio
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
    WHERE mt.production_year BETWEEN 2000 AND 2023
      AND mt.title IS NOT NULL
    GROUP BY mt.id
),
FinalResults AS (
    SELECT et.actor_name, 
           rt.title as movie_title,
           et.role_order,
           fm.production_year,
           fm.keyword_count,
           fm.info_ratio
    FROM ExtendedCast et
    JOIN RecursiveTitles rt ON et.movie_id = rt.id
    JOIN FilteredMovies fm ON rt.id = fm.id
    WHERE et.role_count > 1 
      AND (fm.info_ratio IS NULL OR fm.info_ratio > 0.5)
    ORDER BY fm.production_year DESC, et.role_order
)
SELECT * 
FROM FinalResults
WHERE actor_name IS NOT NULL
  AND movie_title NOT LIKE '%Untitled%'
  AND EXISTS (SELECT 1 FROM movie_info_idx mi WHERE mi.movie_id = FinalResults.movie_id AND mi.info_type_id = 1)
LIMIT 100;

This SQL query performs complex data retrieval and benchmarking from the provided schema, utilizing CTEs to organize the process, incorporates window functions for calculating ranks and averages, and includes various joins with filtering conditions and predicates. The outer SELECT statement retrieves a specific set of results while maintaining the various logical constraints specified in the inner layers.
