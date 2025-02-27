WITH RecursiveMovieCTE AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year,
           ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT a.id AS actor_id, a.name AS actor_name, 
           COUNT(ci.movie_id) AS total_movies,
           STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM aka_name a
    LEFT JOIN cast_info ci ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = ci.movie_id
    GROUP BY a.id, a.name
),
MovieCompanyInfo AS (
    SELECT mc.movie_id, c.name AS company_name, ct.kind AS company_type, 
           COALESCE(STRING_AGG(DISTINCT mi.info ORDER BY mi.info_type_id), 'No Info') AS additional_info
    FROM movie_companies mc
    LEFT JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN company_type ct ON ct.id = mc.company_type_id
    LEFT JOIN movie_info mi ON mi.movie_id = mc.movie_id
    GROUP BY mc.movie_id, c.name, ct.kind
)
SELECT DISTINCT 
       m.movie_id,
       m.title,
       m.production_year,
       ad.actor_name,
       ad.total_movies,
       mci.company_name,
       mci.company_type,
       mci.additional_info
FROM RecursiveMovieCTE m
LEFT JOIN ActorDetails ad ON m.movie_id IN (
       SELECT ci.movie_id 
       FROM cast_info ci 
       WHERE ci.person_id IN (
           SELECT person_id 
           FROM aka_name 
           WHERE name ILIKE '%Smith%'
       )
)
LEFT JOIN MovieCompanyInfo mci ON m.movie_id = mci.movie_id
WHERE (m.production_year < 2000 AND mci.company_type IS NOT NULL)
   OR (m.production_year >= 2000 AND ad.total_movies > 5)
ORDER BY m.production_year DESC, m.title ASC
LIMIT 50;

--- Additional Performance Benchmarking Elements ---
-- You're welcome to adjust the limits and conditions to test various performance aspects.
EXPLAIN ANALYZE;
