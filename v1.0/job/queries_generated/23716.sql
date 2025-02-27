WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        0 AS level
    FROM title t
    WHERE t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        tt.id AS title_id,
        tt.title,
        tt.production_year,
        tt.kind_id,
        th.level + 1
    FROM title_hierarchy th
    JOIN title tt ON th.title_id = tt.episode_of_id  -- Assuming episode_of_id refers to 'parent' title
)
, cast_summary AS (
    SELECT
        ci.movie_id,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        MAX(ci.nr_order) AS highest_order
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
)
, movie_info_extended AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_summary,
        COUNT(*) FILTER (WHERE it.info = 'Awards') AS awards_count
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT 
    th.title,
    th.production_year,
    th.level,
    cs.total_actors,
    cs.highest_order,
    mie.info_summary,
    mie.awards_count,
    CASE 
        WHEN th.kind_id IS NULL THEN 'Unknown Kind'
        ELSE kt.kind
    END AS kind_description
FROM title_hierarchy th
LEFT JOIN cast_summary cs ON th.title_id = cs.movie_id
LEFT JOIN movie_info_extended mie ON th.title_id = mie.movie_id
LEFT JOIN kind_type kt ON th.kind_id = kt.id
ORDER BY th.production_year DESC, th.title;
