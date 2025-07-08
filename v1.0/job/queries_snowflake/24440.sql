
WITH recursive MovieYearCTE AS (
    SELECT t.production_year,
           COUNT(DISTINCT c.person_id) AS total_cast,
           LISTAGG(DISTINCT ka.name, ', ') WITHIN GROUP (ORDER BY ka.name) AS actor_names
    FROM aka_title t
    LEFT JOIN cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN aka_name ka ON c.person_id = ka.person_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year
),
ComplexMovies AS (
    SELECT m.title,
           k.keyword,
           m.production_year,
           COALESCE(mi.info, 'No Information') AS movie_description,
           ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, k.keyword) AS rank
    FROM title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Description')
    WHERE m.production_year IN (SELECT DISTINCT production_year FROM MovieYearCTE WHERE total_cast > 5)
),
FinalBenchmark AS (
    SELECT DISTINCT cm.title AS movie_title,
           cm.production_year,
           cm.movie_description,
           cm.keyword,
           mv.actor_names,
           mv.total_cast,
           CASE
               WHEN mv.total_cast = 0 THEN 'No Cast Available'
               WHEN mv.total_cast IS NULL THEN 'Data Missing'
               ELSE 'Casting Complete'
           END AS cast_availability
    FROM ComplexMovies cm
    JOIN MovieYearCTE mv ON cm.production_year = mv.production_year
    WHERE cm.rank = 1
)
SELECT fb.movie_title,
       fb.production_year,
       fb.movie_description,
       fb.keyword,
       fb.actor_names,
       fb.total_cast,
       fb.cast_availability,
       CASE 
           WHEN fb.production_year IS NULL THEN 'Unknown Year'
           WHEN fb.production_year < 2000 THEN 'Classic'
           WHEN fb.production_year BETWEEN 2000 AND 2010 THEN 'Modern Era'
           ELSE 'Contemporary'
       END AS era_category
FROM FinalBenchmark fb
ORDER BY fb.production_year DESC, fb.total_cast DESC
LIMIT 100;
