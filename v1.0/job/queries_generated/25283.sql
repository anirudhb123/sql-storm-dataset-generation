WITH RankedMovies AS (
  SELECT 
    mt.title,
    mt.production_year,
    COUNT(ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
  FROM 
    aka_title mt
  LEFT JOIN 
    cast_info ci ON mt.id = ci.movie_id
  LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
  LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
  LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
  GROUP BY 
    mt.title, mt.production_year
),
TopRankedMovies AS (
  SELECT 
    title,
    production_year,
    actor_count,
    aka_names,
    keywords
  FROM 
    RankedMovies
  WHERE 
    rank <= 10 -- Get top 10 movies by year
)
SELECT 
  a.production_year,
  COUNT(*) AS num_movies,
  AVG(a.actor_count) AS avg_actors,
  STRING_AGG(a.title, '; ') AS titles,
  STRING_AGG(DISTINCT a.keywords, '; ') AS all_keywords,
  STRING_AGG(DISTINCT a.aka_names, '; ') AS all_aka_names
FROM 
  TopRankedMovies a
GROUP BY 
  a.production_year
ORDER BY 
  a.production_year DESC;
This query ranks movies by the number of actors per production year, aggregates names and keywords, and summarizes this information by year, providing insights into trends in casting and keyword usage across the top ranked films.
