WITH RECURSIVE TitleHierarchy AS (
    SELECT t.id AS title_id, t.title, t.production_year, 0 AS level
    FROM aka_title t
    WHERE t.kind_id = 1  -- Assuming 1 is for movies
    
    UNION ALL
    
    SELECT t2.id, t2.title, t2.production_year, th.level + 1
    FROM aka_title t2
    JOIN TitleHierarchy th ON t2.episode_of_id = th.title_id
),
ActorCount AS (
    SELECT c.movie_id, COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
MovieCompany AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
MovieKeyword AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
MovieInfo AS (
    SELECT mi.movie_id, STRING_AGG(mi.info, '; ') AS movie_info
    FROM movie_info mi
    GROUP BY mi.movie_id
)

SELECT th.title, th.production_year,
       COALESCE(ac.actor_count, 0) AS total_actors,
       COALESCE(mc.company_name, 'No Company') AS production_company,
       COALESCE(mk.keywords, 'No Keywords') AS keywords,
       COALESCE(mi.movie_info, 'No Info') AS additional_info,
       ROW_NUMBER() OVER (ORDER BY th.production_year DESC) AS rank
FROM TitleHierarchy th
LEFT JOIN ActorCount ac ON th.title_id = ac.movie_id
LEFT JOIN MovieCompany mc ON th.title_id = mc.movie_id
LEFT JOIN MovieKeyword mk ON th.title_id = mk.movie_id
LEFT JOIN MovieInfo mi ON th.title_id = mi.movie_id
WHERE th.production_year > 2000
  AND (COALESCE(mc.company_type, 'Unknown') != 'Unknown' OR mk.keywords IS NOT NULL)
ORDER BY th.production_year DESC, th.title;

