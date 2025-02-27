WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, c.title, c.movie_id, 
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY c.production_year DESC) AS rn
    FROM cast_info ci
    JOIN aka_title c ON ci.movie_id = c.id
    WHERE ci.nr_order IS NOT NULL
      AND c.production_year > 2000

    UNION ALL

    SELECT ci.person_id, c.title, c.movie_id, 
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY c.production_year DESC) AS rn
    FROM cast_info ci
    JOIN aka_title c ON ci.movie_id = c.id
    JOIN ActorHierarchy ah ON ah.person_id = ci.person_id
    WHERE ci.nr_order IS NULL
      AND c.production_year <= 2000
),

FilteredMovies AS (
    SELECT m.id AS movie_id, m.title, m.production_year,
           COUNT(DISTINCT ci.person_id) AS actor_count
    FROM aka_title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    WHERE m.production_year IS NOT NULL
      AND m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')
    GROUP BY m.id
    HAVING actor_count > 5
),

DistinctRoles AS (
    SELECT DISTINCT ci.role_id, rt.role 
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
),

CompanyProjects AS (
    SELECT mc.movie_id, COUNT(DISTINCT cn.name) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.country_code IS NOT NULL
    GROUP BY mc.movie_id
)

SELECT DISTINCT ah.person_id, a.name AS actor_name,
       fm.title AS movie_title, fm.production_year,
       dr.role AS character_name,
       cp.company_count as producing_companies,
       CASE 
           WHEN fm.production_year >= 2020 THEN 'Recent'
           WHEN fm.production_year < 2020 AND fm.production_year >= 2010 THEN 'Decade Old'
           WHEN fm.production_year < 2010 AND fm.production_year >= 2000 THEN 'Twenty Century'
           ELSE 'Before 2000'
       END AS production_period
FROM ActorHierarchy ah
JOIN aka_name a ON a.person_id = ah.person_id
JOIN FilteredMovies fm ON ah.movie_id = fm.movie_id
JOIN DistinctRoles dr ON dr.role_id = (SELECT ci.role_id FROM cast_info ci WHERE ci.movie_id = fm.movie_id LIMIT 1)
LEFT JOIN CompanyProjects cp ON cp.movie_id = fm.movie_id
WHERE a.name IS NOT NULL
  AND a.name NOT LIKE '%Unknown%'
  AND EXISTS (
      SELECT 1 
      FROM person_info pi 
      WHERE pi.person_id = ah.person_id 
        AND pi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Biography%')
  )
ORDER BY fm.production_year DESC, actor_name ASC;
