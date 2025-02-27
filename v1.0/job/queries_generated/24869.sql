WITH RecursiveMovies AS (
    SELECT mt.movie_id, t.title, mt.company_id, c.name AS company_name,
           ROW_NUMBER() OVER(PARTITION BY mt.movie_id ORDER BY c.name) AS rn
    FROM movie_companies mt
    JOIN company_name c ON mt.company_id = c.id
    JOIN aka_title t ON mt.movie_id = t.id
    WHERE mt.note IS NOT NULL 
        AND c.country_code IS NOT NULL
),
RankedActors AS (
    SELECT ka.name, COUNT(DISTINCT c.movie_id) AS movie_count,
           RANK() OVER (PARTITION BY ka.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
    FROM aka_name ka
    JOIN cast_info c ON ka.person_id = c.person_id
    WHERE ka.name IS NOT NULL
    GROUP BY ka.name, ka.person_id
),
SubqueryInfo AS (
    SELECT movie_id, STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
           COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info mi ON mk.movie_id = mi.movie_id
    GROUP BY mk.movie_id
),
NullHandlingDemo AS (
    SELECT m.id AS movie_id, 
           COALESCE(k.keywords, 'No Keywords') AS keywords, 
           COALESCE(info.info_type_count, 0) AS info_count
    FROM aka_title m
    LEFT JOIN SubqueryInfo k ON m.id = k.movie_id
    LEFT JOIN (
        SELECT mi.movie_id, 
               COUNT(DISTINCT mi.info_type_id) AS info_type_count
        FROM movie_info mi
        WHERE mi.info IS NOT NULL
        GROUP BY mi.movie_id
    ) info ON m.id = info.movie_id
    WHERE m.production_year IS NOT NULL
)
SELECT r.name AS actor_name, 
       r.movie_count AS total_movies,
       NULLIF(r.actor_rank, 1) AS not_top_actor,
       COALESCE(mv.title, 'Unknown Title') AS movie_title,
       mv.keywords AS movie_keywords
FROM RankedActors r
LEFT JOIN RecursiveMovies mv ON r.movie_count = mv.rn
WHERE r.movie_count > 2 
  AND NOT EXISTS (
      SELECT 1 
      FROM complete_cast cc 
      WHERE cc.movie_id = mv.movie_id
      AND cc.status_id IS NULL
  )
ORDER BY r.movie_count DESC, actor_name, movie_title;
