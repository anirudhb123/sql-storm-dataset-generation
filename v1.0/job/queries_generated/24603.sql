WITH RECURSIVE MovieHierarchy AS (
    SELECT t.id AS movie_id, 
           t.title, 
           t.production_year, 
           0 AS level
    FROM aka_title t
    WHERE t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT t.id AS movie_id, 
           t.title, 
           t.production_year, 
           mh.level + 1
    FROM aka_title t
    JOIN MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT ci.person_id,
           ak.name AS actor_name,
           COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.person_id, ak.name
),
TopActors AS (
    SELECT actor_name,
           movie_count,
           DENSE_RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM CastDetails
    WHERE movie_count > 0
),
MoviesWithCompany AS (
    SELECT m.id AS movie_id, 
           m.title, 
           mc.company_id, 
           cn.name AS company_name, 
           cn.country_code
    FROM aka_title m
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ta.actor_name,
    COALESCE(mwc.company_name, 'Independent') AS production_company,
    mwc.country_code,
    COUNT(mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(mk.keyword) DESC) AS keyword_rank
FROM MovieHierarchy mh
LEFT JOIN MoviesWithCompany mwc ON mh.movie_id = mwc.movie_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN TopActors ta ON mh.movie_id IN (
    SELECT ci.movie_id
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE ak.name = ta.actor_name
)
GROUP BY mh.movie_id, mh.title, mh.production_year, ta.actor_name, mwc.company_name, mwc.country_code
HAVING COUNT(mk.keyword) > 0
ORDER BY mh.production_year DESC, keyword_count DESC;
