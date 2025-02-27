WITH RecursiveTitleHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id
    FROM title t
    WHERE t.id IS NOT NULL

    UNION ALL

    SELECT 
        t2.id AS title_id,
        t2.title,
        t2.production_year,
        t2.kind_id,
        t2.episode_of_id
    FROM title t2
    INNER JOIN RecursiveTitleHierarchy rth ON t2.episode_of_id = rth.title_id
),

AggregatedMovieInfo AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS aggregated_info,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM movie_info mi
    JOIN movie_info_idx mt ON mi.id = mt.info_type_id
    LEFT JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
    GROUP BY mt.movie_id
),

FilteredCasting AS (
    SELECT 
        c.movie_id,
        ct.kind AS role_type,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY c.movie_id, ct.kind
)

SELECT 
    rt.title,
    rt.production_year,
    COALESCE(ama.aggregated_info, 'No Additional Info') AS aggregated_info,
    COALESCE(fc.actor_count, 0) AS actor_count,
    SUM(CASE WHEN it.info IS NOT NULL THEN 1 ELSE 0 END) AS info_type_count,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    ROW_NUMBER() OVER (PARTITION BY rt.production_year ORDER BY rt.title) AS title_rank
FROM RecursiveTitleHierarchy rt
LEFT JOIN AggregatedMovieInfo ama ON rt.id = ama.movie_id
LEFT JOIN FilteredCasting fc ON rt.id = fc.movie_id
LEFT JOIN movie_companies mc ON rt.id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN movie_keyword mk ON rt.id = mk.movie_id
LEFT JOIN info_type it ON mc.id = it.id
WHERE rt.production_year > 2000
  AND NOT EXISTS (
      SELECT 1
      FROM aka_title at
      WHERE at.title = rt.title AND at.production_year < rt.production_year
  )
GROUP BY rt.title, rt.production_year, ama.aggregated_info, fc.actor_count
HAVING COUNT(DISTINCT mk.keyword) > 3
ORDER BY rt.production_year DESC, title_rank;
