WITH 
  RankedMovies AS (
    SELECT 
      t.id AS movie_id,
      t.title,
      t.production_year,
      RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
      aka_title t
  ),
  MovieActors AS (
    SELECT 
      c.movie_id,
      a.name AS actor_name,
      COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
      cast_info c
    JOIN 
      aka_name a ON c.person_id = a.person_id
    GROUP BY 
      c.movie_id, a.name
  ),
  CompanyMovieCounts AS (
    SELECT 
      mc.movie_id,
      COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
      movie_companies mc
    GROUP BY 
      mc.movie_id
  ),
  SelectedMovies AS (
    SELECT 
      rm.movie_id,
      rm.title,
      rm.production_year,
      COALESCE(a.actor_count, 0) AS actor_count,
      COALESCE(c.company_count, 0) AS company_count
    FROM 
      RankedMovies rm
    LEFT JOIN 
      MovieActors a ON rm.movie_id = a.movie_id
    LEFT JOIN 
      CompanyMovieCounts c ON rm.movie_id = c.movie_id
    WHERE 
      rm.title_rank <= 5 AND rm.production_year > 1990
  ),
  FilteredMovies AS (
    SELECT 
      sm.*,
      CASE 
        WHEN sm.actor_count > 5 THEN 'Many Actors'
        WHEN sm.actor_count IS NULL THEN 'No Actors'
        ELSE 'Few Actors' 
      END AS actor_category
    FROM 
      SelectedMovies sm
  )
  
SELECT 
  f.movie_id,
  f.title,
  f.production_year,
  f.actor_count,
  f.company_count,
  f.actor_category,
  STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
  COUNT(DISTINCT ml.linked_movie_id) AS linked_movies
FROM 
  FilteredMovies f
LEFT JOIN 
  movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN 
  keyword k ON mk.keyword_id = k.id
LEFT JOIN 
  movie_link ml ON f.movie_id = ml.movie_id
GROUP BY 
  f.movie_id, f.title, f.production_year, f.actor_count, f.company_count, f.actor_category
HAVING 
  SUM(CASE WHEN f.actor_count IS NULL THEN 1 ELSE 0 END) = 0  -- no null actor counts
ORDER BY 
  f.production_year DESC, f.actor_count DESC;
