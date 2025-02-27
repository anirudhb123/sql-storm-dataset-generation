WITH RECURSIVE title_series AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        1 AS series_level
    FROM title t
    WHERE t.season_nr IS NOT NULL
      AND t.episode_nr IS NOT NULL

    UNION ALL

    SELECT 
        t.id, 
        t.title, 
        t.production_year,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        ts.series_level + 1
    FROM title t
    JOIN title_series ts ON t.episode_of_id = ts.title_id
)
, cast_with_ranks AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
)
, movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        ts.series_level,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM aka_title m 
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN title_series ts ON m.id = ts.title_id
    LEFT JOIN cast_with_ranks ci ON m.id = ci.movie_id
    GROUP BY m.id, m.title, ts.series_level
)
, info_summary AS (
    SELECT 
        m.movie_id,
        m.title,
        m.series_level,
        m.companies,
        m.keyword,
        m.avg_order,
        COUNT(mi.id) AS info_count
    FROM movie_details m
    LEFT JOIN movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY m.movie_id, m.title, m.series_level, m.companies, m.keyword, m.avg_order
)
SELECT 
    i.movie_id,
    i.title,
    i.series_level,
    COALESCE(i.companies, 'No Companies') AS companies,
    i.keyword,
    i.avg_order,
    CASE 
        WHEN i.series_level IS NULL THEN 'Standalone' 
        ELSE 'Part of Series' 
    END AS movie_type,
    i.info_count
FROM info_summary i
WHERE (i.info_count > 0) 
   OR (i.series_level IS NULL AND i.avg_order < 5)
ORDER BY i.title DESC, i.average_order NULLS FIRST;
