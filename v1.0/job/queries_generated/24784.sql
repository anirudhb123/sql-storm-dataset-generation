WITH RECURSIVE ActorHierarchy AS (
    SELECT c.id AS cast_id, c.person_id, c.movie_id, c.nr_order, 
           COALESCE(a.name, 'Unknown Actor') AS actor_name,
           0 AS level
    FROM cast_info c
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.nr_order = 1
    
    UNION ALL
    
    SELECT c.id, c.person_id, c.movie_id, c.nr_order,
           COALESCE(a.name, 'Unknown Actor') AS actor_name,
           ah.level + 1
    FROM cast_info c
    JOIN ActorHierarchy ah ON c.movie_id = ah.movie_id AND c.nr_order > ah.nr_order
    LEFT JOIN aka_name a ON c.person_id = a.person_id
),
MovieInfoCTE AS (
    SELECT m.title, m.production_year, ARRAY_AGG(DISTINCT a.actor_name) AS cast,
           COUNT(DISTINCT mi.info) AS info_count,
           AVG(ki.keyword_count) AS avg_keywords
    FROM aka_title m
    LEFT JOIN (
        SELECT movie_id, COUNT(*) AS keyword_count
        FROM movie_keyword
        GROUP BY movie_id
    ) ki ON m.id = ki.movie_id
    LEFT JOIN ActorHierarchy ah ON m.id = ah.movie_id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    WHERE m.production_year >= 2000
    GROUP BY m.id, m.title, m.production_year
),
RankedMovies AS (
    SELECT title, production_year, cast, info_count, avg_keywords,
           ROW_NUMBER() OVER (ORDER BY info_count DESC, avg_keywords ASC) AS rnk
    FROM MovieInfoCTE
    WHERE info_count IS NOT NULL
)
SELECT r.title, r.production_year, r.cast, r.info_count, r.avg_keywords
FROM RankedMovies r
WHERE rnk <= 10
  AND (r.production_year IS NOT NULL OR r.avg_keywords > 2)
ORDER BY r.info_count DESC, r.avg_keywords DESC NULLS LAST;
