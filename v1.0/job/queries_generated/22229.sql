WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, mt.episode_of_id, 
           mt.season_nr, 1 AS level
    FROM aka_title mt
    WHERE mt.season_nr IS NOT NULL
    
    UNION ALL
    
    SELECT mt.id, mt.title, mt.production_year, mt.episode_of_id, 
           mt.season_nr, mh.level + 1
    FROM aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT ci.movie_id, 
           ak.name AS actor_name, 
           ci.nr_order,
           CTE1.role AS role_description
    FROM cast_info ci
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN role_type CTE1 ON ci.role_id = CTE1.id
),
KeywordMatch AS (
    SELECT mt.movie_id, 
           STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title mt ON mk.movie_id = mt.id
    GROUP BY mt.movie_id
),
MovieInfoDetail AS (
    SELECT mt.id AS movie_id, 
           COALESCE(mi.info, 'No Info') AS movie_info,
           COUNT(DISTINCT mc.company_id) AS company_count,
           MAX(CASE WHEN it.id IN (SELECT DISTINCT info_type_id FROM movie_info WHERE movie_id = mt.id) THEN 'Related Info' ELSE NULL END) AS related_info
    FROM aka_title mt
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mt.id
)
SELECT mh.movie_id, 
       mh.title,
       mh.production_year,
       cd.actor_name,
       cd.role_description,
       km.keywords,
       md.movie_info,
       md.company_count,
       CASE 
           WHEN md.related_info IS NOT NULL THEN 'Has Related Info'
           ELSE 'No Related Info'
       END AS info_status,
       COUNT(DISTINCT cd.actor_name) OVER (PARTITION BY mh.movie_id) AS total_actors
FROM MovieHierarchy mh
LEFT JOIN CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN KeywordMatch km ON mh.movie_id = km.movie_id
LEFT JOIN MovieInfoDetail md ON mh.movie_id = md.movie_id
WHERE mh.production_year >= 2000
  AND (mh.season_nr IS NULL OR mh.season_nr BETWEEN 1 AND 10)
  AND COALESCE(cd.role_description, '') NOT LIKE '%Extra%'
ORDER BY mh.production_year DESC, mh.title
LIMIT 50 OFFSET 0;
