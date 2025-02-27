WITH MovieDetails AS (
  SELECT 
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    a.name AS actor_name,
    p.gender AS actor_gender,
    m.keyword AS associated_keyword,
    COUNT(DISTINCT a.id) AS actor_count
  FROM 
    title t
  JOIN 
    movie_companies mc ON t.id = mc.movie_id
  JOIN 
    company_type c ON mc.company_type_id = c.id
  JOIN 
    cast_info ci ON t.id = ci.movie_id
  JOIN 
    aka_name a ON ci.person_id = a.person_id
  JOIN 
    name p ON a.person_id = p.imdb_id
  JOIN 
    movie_keyword mk ON t.id = mk.movie_id
  JOIN 
    keyword m ON mk.keyword_id = m.id
  GROUP BY 
    t.title, 
    t.production_year, 
    c.kind, 
    a.name, 
    p.gender, 
    m.keyword
),
ActorSummary AS (
  SELECT 
    actor_name, 
    actor_gender, 
    COUNT(movie_title) AS number_of_movies 
  FROM 
    MovieDetails
  GROUP BY 
    actor_name, 
    actor_gender
)
SELECT 
  MD.movie_title, 
  MD.production_year, 
  MD.company_type,
  ASUM.actor_name,
  ASUM.actor_gender,
  ASUM.number_of_movies
FROM 
  MovieDetails MD
JOIN 
  ActorSummary ASUM ON MD.actor_name = ASUM.actor_name
WHERE 
  MD.production_year BETWEEN 2000 AND 2023
ORDER BY 
  MD.production_year DESC,
  ASUM.number_of_movies DESC,
  MD.movie_title;
