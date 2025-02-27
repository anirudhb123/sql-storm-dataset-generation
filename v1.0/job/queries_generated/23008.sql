WITH 
  RankedMovies AS (
    SELECT 
      mt.title AS movie_title,
      mt.production_year,
      COUNT(DISTINCT ci.person_id) AS cast_count,
      ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast size,
      MAX(CASE WHEN ci.role_id IS NOT NULL THEN 'Has Roles' ELSE 'No Roles' END) as role_info
    FROM 
      aka_title mt 
      LEFT JOIN cast_info ci ON mt.id = ci.movie_id 
    GROUP BY 
      mt.id, mt.title, mt.production_year
  ),
  MovieWithKeyword AS (
    SELECT 
      mv.movie_title,
      mv.production_year,
      mk.keyword AS associated_keyword
    FROM 
      RankedMovies mv
      JOIN movie_keyword mk ON mv.movie_title = mk.movie_id
    WHERE 
      mv.rank_by_cast_size <= 5
  ),
  ActorDetails AS (
    SELECT 
      a.name,
      a.person_id,
      COUNT(DISTINCT ci.movie_id) AS movies_played,
      STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
      MAX(info.info) AS max_info
    FROM 
      aka_name a
      LEFT JOIN cast_info ci ON a.person_id = ci.person_id 
      LEFT JOIN movie_keyword mk ON ci.movie_id = mk.movie_id 
      LEFT JOIN person_info info ON a.person_id = info.person_id
    WHERE 
      a.name IS NOT NULL AND a.name <> ''
    GROUP BY 
      a.name, a.person_id
  ),
  CompanyDetails AS (
    SELECT 
      co.name AS company_name,
      COUNT(DISTINCT mc.movie_id) AS movies_produced
    FROM 
      company_name co
      LEFT JOIN movie_companies mc ON co.id = mc.company_id
    WHERE 
      co.country_code IS NOT NULL
    GROUP BY 
      co.name
  )
  
SELECT 
  mv.movie_title,
  mv.production_year,
  mv.cast_count,
  mv.role_info,
  ak.name AS actor_name,
  ak.movies_played,
  ak.keywords,
  cd.company_name,
  cd.movies_produced 
FROM 
  RankedMovies mv
  JOIN ActorDetails ak ON mv.cast_count > 5 AND mu.role_info = 'Has Roles'
  LEFT JOIN CompanyDetails cd ON mv.production_year BETWEEN 1990 AND 2020 AND ak.movies_played > 2
WHERE 
  mv.production_year IS NOT NULL
  AND mv.cast_count IS NOT NULL
ORDER BY 
  mv.production_year DESC, mv.cast_count DESC;

-- Additionally, to explore edge cases for NULL handling
UNION ALL 

SELECT 
  NULL AS movie_title,
  NULL AS production_year,
  0 AS cast_count,
  NULL AS role_info,
  ak.name AS actor_name,
  ak.movies_played,
  ak.keywords,
  cd.company_name,
  cd.movies_produced 
FROM 
  ActorDetails ak
  FULL OUTER JOIN CompanyDetails cd ON ak.person_id IS NULL OR cd.company_name IS NULL
WHERE 
  ak.movies_played < 1 OR cd.movies_produced IS NULL;


