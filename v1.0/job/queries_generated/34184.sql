WITH RECURSIVE TitleHierarchy AS (
    SELECT t.id AS title_id, t.title, t.production_year, t.episode_of_id, 
           t.season_nr, 1 AS level
    FROM title t
    WHERE t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT t.id, t.title, t.production_year, t.episode_of_id, 
           t.season_nr, th.level + 1
    FROM title t
    JOIN TitleHierarchy th ON t.episode_of_id = th.title_id
),
MovieKeywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
InfoTypes AS (
    SELECT mi.movie_id, 
           STRING_AGG(it.info || ' : ' || mi.info, '; ') AS movie_info
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
),
CastWithRoles AS (
    SELECT ca.movie_id,
           a.name AS actor_name,
           r.role AS role_name,
           ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS role_order
    FROM cast_info ca
    JOIN aka_name a ON ca.person_id = a.person_id
    JOIN role_type r ON ca.role_id = r.id
)

SELECT th.title, th.production_year, th.level,
       CASE WHEN mk.keywords IS NOT NULL THEN mk.keywords ELSE 'No Keywords' END AS keywords,
       COALESCE(it.movie_info, 'No Additional Information') AS additional_info,
       STRING_AGG(DISTINCT cwr.actor_name || ' (' || cwr.role_name || ')', ', ') AS actors
FROM TitleHierarchy th
LEFT JOIN MovieKeywords mk ON th.title_id = mk.movie_id
LEFT JOIN InfoTypes it ON th.title_id = it.movie_id
LEFT JOIN CastWithRoles cwr ON th.title_id = cwr.movie_id
GROUP BY th.title, th.production_year, th.level, mk.keywords, it.movie_info
ORDER BY th.production_year DESC, th.title;
