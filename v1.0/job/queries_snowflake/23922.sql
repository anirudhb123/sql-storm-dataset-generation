
WITH RECURSIVE title_hierarchy AS (
    SELECT t.id AS title_id, t.title, t.production_year, t.episode_of_id, 
           ROW_NUMBER() OVER (PARTITION BY t.episode_of_id ORDER BY t.season_nr, t.episode_nr) AS episode_rank
    FROM title t
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvEpisode'))
    
    UNION ALL
    
    SELECT tt.id, tt.title, tt.production_year, tt.episode_of_id,
           ROW_NUMBER() OVER (PARTITION BY tt.episode_of_id ORDER BY tt.season_nr, tt.episode_nr) AS episode_rank
    FROM title tt
    INNER JOIN title_hierarchy th ON tt.episode_of_id = th.title_id
),
movie_details AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           ARRAY_AGG(k.keyword) AS keywords,
           COUNT(DISTINCT mi.info) FILTER (WHERE it.info IN ('summary', 'plot')) AS summary_count,
           MAX(CASE WHEN ci.role_id IS NOT NULL THEN ci.role_id END) AS primary_role_id
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    GROUP BY mt.id, mt.title, mt.production_year
    HAVING COUNT(DISTINCT k.keyword) > 5
)
SELECT th.title, th.production_year, 
       COALESCE(md.keywords, ARRAY_CONSTRUCT()) AS keywords,
       md.summary_count,
       (SELECT COUNT(*) FROM complete_cast c WHERE c.movie_id = md.movie_id) AS complete_cast_count,
       (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = md.movie_id AND ci.nr_order IS NOT NULL) AS ordered_cast_count,
       CASE WHEN md.primary_role_id IS NULL THEN 'No roles' ELSE 'Roles exist' END AS role_status
FROM title_hierarchy th
LEFT JOIN movie_details md ON th.title_id = md.movie_id
WHERE th.episode_rank = 1
GROUP BY th.title, th.production_year, md.keywords, md.summary_count, md.movie_id, md.primary_role_id
ORDER BY th.production_year DESC, th.title ASC
LIMIT 100 OFFSET 50;
