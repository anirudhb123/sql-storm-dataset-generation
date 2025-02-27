WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, 
           p.name AS actor_name, 
           ci.movie_id,
           t.title AS movie_title,
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS rn
    FROM cast_info ci
    JOIN aka_name p ON ci.person_id = p.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    WHERE t.production_year >= 2000 

    UNION ALL

    SELECT ci.person_id, 
           p.name, 
           ci.movie_id,
           t.title,
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS rn
    FROM cast_info ci
    JOIN aka_name p ON ci.person_id = p.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    JOIN ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE t.production_year < ah.rn
)

SELECT ah.actor_name, 
       COUNT(DISTINCT ah.movie_id) AS movie_count,
       STRING_AGG(DISTINCT ah.movie_title, ', ') AS movies,
       AVG(ti.info::float) AS average_info_type
FROM ActorHierarchy ah
LEFT JOIN movie_info mi ON ah.movie_id = mi.movie_id
LEFT JOIN info_type ti ON mi.info_type_id = ti.id
GROUP BY ah.actor_name
HAVING COUNT(DISTINCT ah.movie_id) > 3
ORDER BY average_info_type DESC
LIMIT 10;

-- Joining with company data to get the production companies for the movies acted in by the top actors
SELECT a.actor_name, 
       a.movie_title, 
       com.name AS production_company, 
       a.movie_count
FROM (
    SELECT ah.actor_name, 
           ah.movie_id,
           COUNT(DISTINCT ah.movie_id) AS movie_count,
           STRING_AGG(DISTINCT ah.movie_title, ', ') AS movies
    FROM ActorHierarchy ah
    GROUP BY ah.actor_name, ah.movie_id
) AS a
JOIN movie_companies mc ON a.movie_id = mc.movie_id
JOIN company_name com ON mc.company_id = com.id
WHERE com.country_code IS NOT NULL
ORDER BY a.movie_count DESC
LIMIT 5;
