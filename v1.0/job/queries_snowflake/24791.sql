
WITH RecursiveActor AS (
    SELECT ci.person_id, 
           COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info AS ci
    JOIN aka_name AS ak ON ci.person_id = ak.person_id
    WHERE ak.name IS NOT NULL
    GROUP BY ci.person_id
),
RankedActors AS (
    SELECT ra.person_id,
           ra.movie_count,
           DENSE_RANK() OVER (ORDER BY ra.movie_count DESC) AS actor_rank
    FROM RecursiveActor AS ra
),
TopActors AS (
    SELECT person_id
    FROM RankedActors
    WHERE actor_rank <= 10
),
MovieDetails AS (
    SELECT t.id AS movie_id, 
           t.title, 
           t.production_year,
           COALESCE(ARRAY_AGG(DISTINCT ak.name), ARRAY_CONSTRUCT('No Cast')) AS actor_names
    FROM aka_title AS t
    LEFT JOIN cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY t.id, t.title, t.production_year
)
SELECT md.movie_id, 
       md.title, 
       md.production_year, 
       ARRAY_TO_STRING(md.actor_names, ', ') AS actor_names, 
       (CASE 
           WHEN md.production_year IS NULL THEN 'Unknown Year' 
           ELSE CAST(md.production_year AS STRING) 
        END) AS production_year_text,
       (SELECT COUNT(*)
        FROM movie_info AS mi
        WHERE mi.movie_id = md.movie_id
          AND EXISTS (SELECT 1 FROM info_type WHERE id = mi.info_type_id AND info = 'rating')) AS rating_info_count,
       (SELECT COUNT(*)
        FROM movie_keyword AS mk
        WHERE mk.movie_id = md.movie_id) AS keyword_count,
       (SELECT LISTAGG(kt.keyword, ', ') 
        FROM movie_keyword AS mk
        JOIN keyword AS kt ON mk.keyword_id = kt.id
        WHERE mk.movie_id = md.movie_id) AS movie_keywords
FROM MovieDetails AS md
WHERE EXISTS (SELECT 1 
              FROM TopActors AS ta 
              JOIN cast_info AS ci ON ci.person_id = ta.person_id
              WHERE ci.movie_id = md.movie_id)
ORDER BY md.production_year DESC, 
         md.title ASC;
