WITH RankedMovies AS (
  SELECT 
    t.id AS movie_id,
    t.title,
    t.production_year,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
  FROM 
    aka_title t
),
MovieGenres AS (
  SELECT 
    m.movie_id,
    STRING_AGG(DISTINCT k.keyword, ', ') AS genres
  FROM 
    movie_keyword mk
  JOIN 
    keyword k ON mk.keyword_id = k.id
  JOIN 
    aka_title m ON mk.movie_id = m.id
  GROUP BY 
    m.movie_id
),
PopularActors AS (
  SELECT 
    c.movie_id,
    ak.name,
    COUNT(c.person_id) AS actor_count
  FROM 
    cast_info c
  JOIN 
    aka_name ak ON c.person_id = ak.person_id
  GROUP BY 
    c.movie_id, ak.name
  HAVING 
    COUNT(c.person_id) > 1
),
MoviesWithStatistics AS (
  SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mg.genres, 'Unknown') AS genres,
    COALESCE(pa.actor_count, 0) AS popular_actor_count,
    COUNT(DISTINCT ci.person_id) AS total_actors
  FROM 
    RankedMovies rm
  LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
  LEFT JOIN 
    PopularActors pa ON rm.movie_id = pa.movie_id
  LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
  GROUP BY 
    rm.movie_id, rm.title, rm.production_year, mg.genres, pa.actor_count
),
FinalMovieStats AS (
  SELECT 
    *,
    CASE 
      WHEN production_year < 2000 THEN 'Classic'
      WHEN production_year BETWEEN 2000 AND 2010 THEN 'Modern'
      ELSE 'Recent'
    END AS era,
    ROW_NUMBER() OVER (ORDER BY popular_actor_count DESC, total_actors DESC) AS movie_rank
  FROM 
    MoviesWithStatistics
)
SELECT 
  fms.movie_id,
  fms.title,
  fms.production_year,
  fms.genres,
  fms.popular_actor_count,
  fms.total_actors,
  fms.era
FROM 
  FinalMovieStats fms
WHERE 
  fms.popular_actor_count > 0
  AND fms.total_actors > 2
  AND (fms.production_year BETWEEN 1990 AND 2023 OR fms.genres != 'Unknown')
ORDER BY 
  fms.era ASC, 
  fms.movie_rank ASC
LIMIT 100;
