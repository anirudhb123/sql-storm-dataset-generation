WITH RecursiveMovieRoles AS (
    SELECT ci.movie_id, ci.person_id, ci.role_id, ct.kind AS role_name,
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM cast_info ci
    JOIN role_type ct ON ci.role_id = ct.id
),
MovieDetails AS (
    SELECT t.title, t.production_year, ka.name AS actor_name, r.role_name,
           COALESCE(mk.keyword, 'No Keyword') AS movie_keyword
    FROM title t
    LEFT JOIN aka_title ka_t ON ka_t.movie_id = t.id
    LEFT JOIN aka_name ka ON ka.id = ka_t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN RecursiveMovieRoles r ON r.movie_id = t.id
    WHERE t.production_year >= 2000
),
AggregatedMovies AS (
    SELECT title, production_year, STRING_AGG(DISTINCT actor_name, ', ') AS actors,
           STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
           COUNT(DISTINCT role_name) AS role_count
    FROM MovieDetails
    GROUP BY title, production_year
),
TopMovies AS (
    SELECT *, RANK() OVER (ORDER BY role_count DESC) AS movie_rank
    FROM AggregatedMovies
    WHERE role_count > 2
)

SELECT tm.title, tm.production_year, tm.actors, 
       NULLIF(tm.keywords, '') AS cleaned_keywords,
       CASE 
           WHEN tm.movie_rank <= 10 THEN 'Top Rank' 
           ELSE 'Other Rank'
       END AS rank_category
FROM TopMovies tm
WHERE cleaned_keywords IS NOT NULL 
  AND EXISTS (
      SELECT 1 
      FROM movie_info mi 
      WHERE mi.movie_id IN (
          SELECT movie_id FROM title WHERE title = tm.title
      ) AND mi.info_type_id IN (
          SELECT it.id FROM info_type it WHERE it.info = 'Genre'
      ) AND mi.info IS NOT NULL
  )
ORDER BY tm.production_year DESC, tm.movie_rank;
