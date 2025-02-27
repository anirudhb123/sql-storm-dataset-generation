WITH RecursiveMovieInfo AS (
    SELECT mt.id AS movie_id,
           mt.title,
           mt.production_year,
           mt.kind_id,
           COALESCE(mk.keyword, 'Unknown') AS keyword,
           ROW_NUMBER() OVER(PARTITION BY mt.id ORDER BY mk.id) AS keyword_rank
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    WHERE mt.production_year >= 2000
    AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Movie%')
),
ExpandedCast AS (
    SELECT ci.movie_id,
           a.name AS actor_name,
           ci.person_role_id,
           ROW_NUMBER() OVER(PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE a.name IS NOT NULL
),
OuterJoinData AS (
    SELECT rm.movie_id,
           rm.title,
           rm.production_year,
           ec.actor_name,
           ec.actor_order,
           COUNT(DISTINCT mk.keyword) OVER(PARTITION BY rm.movie_id) AS keyword_count
    FROM RecursiveMovieInfo rm
    LEFT JOIN ExpandedCast ec ON rm.movie_id = ec.movie_id
)
SELECT omd.movie_id,
       omd.title,
       omd.production_year,
       omd.actor_name,
       COALESCE(omd.keyword_count, 0) AS total_keywords,
       CASE 
           WHEN omd.actor_order IS NULL THEN 'No Cast'
           WHEN omd.actor_order <= 3 THEN 'Top Cast'
           ELSE 'Supporting Cast'
       END AS cast_type
FROM OuterJoinData omd
WHERE omd.production_year IN (
    SELECT DISTINCT production_year
    FROM OuterJoinData
    WHERE actor_order IS NOT NULL
) 
AND (omd.actor_name IS NOT NULL OR omd.keyword_count > 0)
ORDER BY omd.production_year DESC, omd.movie_id;
