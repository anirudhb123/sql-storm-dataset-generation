WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT m.id AS movie_id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.level < 5
),
ActorMovieInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY mt.production_year DESC) AS recent_movie_rank
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title mt ON ci.movie_id = mt.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.imdb_id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    STRING_AGG(DISTINCT ai.actor_name, ', ') AS Actors,
    STRING_AGG(DISTINCT ci.company_name || ' (' || ci.company_type || ')', ', ') AS Companies,
    COUNT(DISTINCT ai.actor_id) AS Actor_Count,
    COUNT(DISTINCT ci.company_name) AS Company_Count,
    COALESCE(MAX(ai.recent_movie_rank), 0) AS Latest_Movie_Rank,
    SUM(CASE WHEN ai.recent_movie_rank = 1 THEN 1 ELSE 0 END) AS Recent_Award_Eligible_Cast
FROM MovieHierarchy mh
LEFT JOIN ActorMovieInfo ai ON mh.movie_id = ai.movie_title
LEFT JOIN CompanyInfo ci ON mh.movie_id = ci.movie_id
WHERE mh.level BETWEEN 1 AND 5
GROUP BY mh.movie_id, mh.title, mh.production_year
ORDER BY mh.production_year DESC, Movie_Title
LIMIT 50;
