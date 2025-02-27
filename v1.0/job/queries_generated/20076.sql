WITH RECURSIVE FilmSeries AS (
    -- Recursive CTE to capture series information, joining episodes to their parent series
    SELECT t.id AS title_id, 
           t.title AS series_title, 
           t.season_nr, 
           t.episode_nr, 
           CAST(NULL AS INTEGER) AS parent_id,
           t.production_year,
           ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.season_nr, t.episode_nr) AS ep_order
    FROM title t
    WHERE t.episode_of_id IS NULL
    
    UNION ALL 
    
    SELECT t.id AS title_id, 
           t.title AS episode_title, 
           t.season_nr, 
           t.episode_nr, 
           fs.title_id AS parent_id, 
           t.production_year,
           ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.season_nr, t.episode_nr) AS ep_order
    FROM title t
    JOIN FilmSeries fs ON t.episode_of_id = fs.title_id
)
, ActorRoles AS (
    -- CTE to aggregate actor roles and join with film series information
    SELECT c.movie_id,
           a.name AS actor_name,
           COUNT(DISTINCT c.role_id) AS role_count,
           STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id, a.name
), MovieKeywordInfo AS (
    -- CTE to gather movie keywords with their associated movies
    SELECT mk.movie_id,
           k.keyword,
           COUNT(mk.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id, k.keyword
)
-- Final query to combine all the information for performance benchmarking
SELECT fs.series_title,
       fs.season_nr,
       fs.episode_nr,
       COALESCE(ak.keyword, 'No keyword') AS keyword,
       COALESCE(ar.actor_name, 'Unknown') AS actor_name,
       fs.production_year,
       ar.role_count,
       CASE 
           WHEN ar.role_count > 3 THEN 'Lead'
           WHEN ar.role_count BETWEEN 1 AND 3 THEN 'Support'
           ELSE 'Cameo'
       END AS role_category,
       MAX(CASE 
           WHEN ar.role_count > 0 AND ak.keyword_count > 0 THEN 'High Engagement'
           ELSE 'Low Engagement'
       END) AS engagement_status
FROM FilmSeries fs
LEFT JOIN ActorRoles ar ON fs.title_id = ar.movie_id
LEFT JOIN MovieKeywordInfo ak ON fs.title_id = ak.movie_id
WHERE fs.production_year IS NOT NULL
  AND (fs.season_nr IS NULL OR fs.episode_nr IS NULL)
GROUP BY fs.series_title, fs.season_nr, fs.episode_nr, ak.keyword, ar.actor_name, fs.production_year, ar.role_count
ORDER BY fs.season_nr, fs.episode_nr DESC, ar.role_count DESC
LIMIT 100;
