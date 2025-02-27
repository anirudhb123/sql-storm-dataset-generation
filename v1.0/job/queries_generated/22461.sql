WITH RecursiveMovieCTE AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year,
           ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
      AND mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorRole AS (
    SELECT ci.movie_id, ak.name AS actor_name, rt.role AS role
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
),
AggregateKeyword AS (
    SELECT mk.movie_id,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CompanyDetails AS (
    SELECT mc.movie_id,
           STRING_AGG(DISTINCT cn.name, ', ') AS companies,
           STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
TotalMovies AS (
    SELECT COUNT(DISTINCT mt.id) AS total_movies
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
)
SELECT rmc.movie_id, rmc.title, rmc.production_year, ar.actor_name,
       ar.role, ag.keywords, cd.companies, cd.company_types, tm.total_movies,
       CASE
           WHEN rmc.production_year IS NOT NULL THEN rmc.production_year
           ELSE 'Unknown Year' END AS year_label
FROM RecursiveMovieCTE rmc
LEFT JOIN ActorRole ar ON rmc.movie_id = ar.movie_id
LEFT JOIN AggregateKeyword ag ON rmc.movie_id = ag.movie_id
LEFT JOIN CompanyDetails cd ON rmc.movie_id = cd.movie_id
CROSS JOIN TotalMovies tm
WHERE (ar.role IS NOT NULL OR ar.role IS NULL)  -- Bizarre NULL logic for demonstration
ORDER BY rmc.production_year DESC, rmc.title ASC;
