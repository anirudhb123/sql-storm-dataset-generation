WITH Recursive_Cast AS (
    SELECT ci.movie_id, ci.person_id, ci.nr_order,
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM cast_info ci
    WHERE ci.nr_order IS NOT NULL
),
Movie_Info_CTE AS (
    SELECT mi.movie_id, 
           STRING_AGG(DISTINCT mi.info, ', ') AS info_details,
           COUNT(DISTINCT mi.id) AS total_info
    FROM movie_info mi
    GROUP BY mi.movie_id
),
Filtered_Movies AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           mi.info_details,
           mi.total_info,
           cc.kind AS company_kind
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN comp_cast_type cc ON mc.company_type_id = cc.id
    LEFT JOIN Movie_Info_CTE mi ON m.id = mi.movie_id
    WHERE m.production_year IS NOT NULL AND (cc.kind IS NOT NULL OR m.title ILIKE '%adventure%')
)
SELECT f.movie_id,
       f.title,
       f.production_year,
       COALESCE(f.info_details, 'No Info') AS info_details,
       f.total_info,
       COALESCE(f.company_kind, 'Unknown') AS company_kind,
       COUNT(DISTINCT rc.person_id) AS actor_count,
       CASE 
           WHEN COUNT(DISTINCT rc.person_id) > 5 THEN 'Ensemble Cast'
           WHEN COUNT(DISTINCT rc.person_id) BETWEEN 2 AND 5 THEN 'Small Cast'
           ELSE 'Solo Performance'
       END AS cast_size_category
FROM Filtered_Movies f
LEFT JOIN Recursive_Cast rc ON f.movie_id = rc.movie_id
GROUP BY f.movie_id, f.title, f.production_year, f.info_details, f.total_info, f.company_kind
ORDER BY f.production_year DESC, f.title ASC
LIMIT 50;

-- Note: This query includes several elements:
-- 1. CTEs for recursive casting and movie information aggregation.
-- 2. Outer joins to include possible NULL values on company and info details.
-- 3. Complicated predicates around movie information filtering.
-- 4. Usage of string aggregation to combine information.
-- 5. NULL handling with COALESCE to ensure no NULL returns.
-- 6. Categorization of the cast based on a count of actors.
