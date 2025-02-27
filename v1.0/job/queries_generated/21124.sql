WITH RECURSIVE ActorHierarchy AS (
    SELECT a.id AS actor_id, 
           a.name AS actor_name, 
           a.md5sum, 
           0 AS depth 
    FROM aka_name a
    WHERE a.name ILIKE 'Johnny Depp%'  -- Starting actor

    UNION ALL 

    SELECT a.id, 
           a.name,
           a.md5sum,
           ah.depth + 1 
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN ActorHierarchy ah ON ci.movie_id IN (
        SELECT movie_id 
        FROM cast_info ci2 
        WHERE ci2.person_id = ah.actor_id
    )
    WHERE ah.depth < 3  -- Limit depth for performance
),
MovieInfo AS (
    SELECT mt.title, 
           mt.production_year,
           STRING_AGG(DISTINCT ak.name, ', ') AS actors, 
           COUNT(DISTINCT mk.keyword) AS keyword_count,
           ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS movie_rank
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')
    GROUP BY mt.id, mt.title, mt.production_year
    HAVING COUNT(DISTINCT ak.id) >= 2  -- At least two distinct actors
),
QualifiedMovies AS (
    SELECT mi.title, 
           mi.production_year, 
           mi.actors,
           mi.keyword_count,
           CASE 
               WHEN mi.keyword_count = 0 THEN 'No keywords' 
               WHEN mi.keyword_count > 10 THEN 'Many keywords' 
               ELSE 'Few keywords' 
           END AS keyword_description
    FROM MovieInfo mi
    WHERE mi.movie_rank = 1
)
SELECT qm.title, 
       qm.production_year, 
       qm.actors, 
       qm.keyword_count,
       qm.keyword_description,
       COALESCE((
           SELECT COUNT(*) 
           FROM movie_info m
           WHERE m.movie_id = (SELECT id FROM aka_title WHERE title = qm.title LIMIT 1) 
             AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
       ), 0) AS box_office_count,
       CASE
           WHEN qm.production_year IS NULL THEN 'Unknown Year'
           ELSE TO_CHAR(qm.production_year)
       END AS production_year_display
FROM QualifiedMovies qm
ORDER BY qm.production_year DESC
LIMIT 100;
