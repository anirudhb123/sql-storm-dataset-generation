WITH NameAgg AS (
  SELECT 
    ak.person_id,
    STRING_AGG(DISTINCT ak.name, ', ') AS ak_names,
    STRING_AGG(DISTINCT c.name, ', ') AS char_names
  FROM
    aka_name ak
  LEFT JOIN
    cast_info ca ON ak.person_id = ca.person_id
  LEFT JOIN
    char_name c ON ca.person_id = c.imdb_id
  GROUP BY 
    ak.person_id
),
MovieAgg AS (
  SELECT 
    m.id AS movie_id,
    m.title AS movie_title,
    STRING_AGG(DISTINCT co.name, ', ') AS production_companies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
  FROM 
    aka_title m
  LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
  LEFT JOIN 
    company_name co ON mc.company_id = co.id
  LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
  LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
  GROUP BY 
    m.id, m.title
)
SELECT 
  na.ak_names,
  na.char_names,
  ma.movie_id,
  ma.movie_title,
  ma.production_companies,
  ma.keywords
FROM 
  NameAgg na
JOIN 
  cast_info ca ON na.person_id = ca.person_id
JOIN 
  MovieAgg ma ON ca.movie_id = ma.movie_id
WHERE 
  ma.movie_title ILIKE '%adventure%'
ORDER BY 
  ma.movie_title ASC;