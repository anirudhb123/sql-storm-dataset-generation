WITH RECURSIVE RecursiveMovies AS (
    SELECT t.id AS movie_id, t.title AS movie_title, t.production_year, 
           ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_order
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
    UNION ALL
    SELECT km.movie_id, k.title AS movie_title, k.production_year, 
           ROW_NUMBER() OVER (PARTITION BY k.production_year ORDER BY k.title) AS year_order
    FROM movie_link ml
    JOIN aka_title k ON ml.linked_movie_id = k.id
    JOIN RecursiveMovies km ON ml.movie_id = km.movie_id
), 
MovieCast AS (
    SELECT c.movie_id, cn.name AS cast_name, 
           COUNT(CASE WHEN cr.kind IS NOT NULL THEN 1 END) OVER (PARTITION BY c.movie_id) AS cast_count,
           SUM(CASE WHEN cr.kind IS NOT NULL THEN 1 ELSE 0 END) AS total_roles
    FROM cast_info c
    LEFT JOIN char_name cn ON c.person_id = cn.imdb_id
    LEFT JOIN comp_cast_type cr ON c.person_role_id = cr.id
), 
MovieKeywords AS (
    SELECT mk.movie_id, COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
), 
DetailedMovies AS (
    SELECT rm.movie_id, rm.movie_title, rm.production_year, 
           COALESCE(mc.cast_count, 0) AS cast_count,
           COALESCE(mk.keyword_count, 0) AS keyword_count,
           CASE 
               WHEN COALESCE(mc.cast_count, 0) >= 5 THEN 'Hit'
               WHEN COALESCE(mc.cast_count, 0) < 5 AND COALESCE(mk.keyword_count, 0) > 3 THEN 'Cult'
               ELSE 'Flop'
           END AS movie_fate 
    FROM RecursiveMovies rm
    LEFT JOIN MovieCast mc ON rm.movie_id = mc.movie_id
    LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
), 
TopMovies AS (
    SELECT movie_id, movie_title, production_year, cast_count, keyword_count, movie_fate,
           RANK() OVER (ORDER BY production_year DESC, cast_count DESC, keyword_count DESC) AS rank_within_year
    FROM DetailedMovies
)
SELECT movie_title, production_year, cast_count, keyword_count, movie_fate
FROM TopMovies
WHERE movie_fate = 'Hit'
AND production_year IN (
    SELECT DISTINCT production_year 
    FROM TopMovies 
    WHERE rank_within_year <= 10
)
ORDER BY production_year DESC, cast_count DESC;
