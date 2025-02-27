WITH RankedMovies AS (
  SELECT
    t.id AS movie_id,
    t.title,
    t.production_year,
    COUNT(ci.person_id) AS num_cast_members,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
  FROM
    aka_title t
  JOIN
    cast_info ci ON ci.movie_id = t.id
  JOIN
    aka_name ak ON ak.person_id = ci.person_id
  WHERE
    t.production_year >= 2000 
  GROUP BY
    t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
  SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.num_cast_members,
    rm.cast_names,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
  FROM
    RankedMovies rm
  LEFT JOIN
    movie_keyword mk ON mk.movie_id = rm.movie_id
  LEFT JOIN
    keyword k ON k.id = mk.keyword_id
  GROUP BY
    rm.movie_id, rm.title, rm.production_year, rm.num_cast_members, rm.cast_names
),
FinalOutput AS (
  SELECT
    mwk.movie_id,
    mwk.title,
    mwk.production_year,
    mwk.num_cast_members,
    mwk.cast_names,
    mwk.keywords,
    CASE 
      WHEN mwk.num_cast_members > 10 THEN 'Large Cast'
      WHEN mwk.num_cast_members BETWEEN 5 AND 10 THEN 'Medium Cast'
      ELSE 'Small Cast'
    END AS cast_size
  FROM
    MoviesWithKeywords mwk
)
SELECT
  fo.movie_id,
  fo.title,
  fo.production_year,
  fo.num_cast_members,
  fo.cast_names,
  fo.keywords,
  fo.cast_size
FROM
  FinalOutput fo
ORDER BY
  fo.production_year DESC,
  fo.num_cast_members DESC
LIMIT 50;