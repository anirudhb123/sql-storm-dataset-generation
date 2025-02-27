WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, 
           p.name AS actor_name, 
           1 AS level
    FROM cast_info ci
    JOIN aka_name p ON ci.person_id = p.person_id
    WHERE ci.movie_id IS NOT NULL

    UNION ALL

    SELECT ci.person_id, 
           p.name AS actor_name, 
           ah.level + 1
    FROM cast_info ci
    JOIN aka_name p ON ci.person_id = p.person_id
    JOIN ActorHierarchy ah ON ci.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id LIMIT 1)
    WHERE ah.level < 5
),

MovieCompanies AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),

MovieDetails AS (
    SELECT t.id AS movie_id, 
           t.title, 
           t.production_year, 
           mt.kind AS movie_type,
           (SELECT COUNT(DISTINCT ci.person_id) 
            FROM cast_info ci 
            WHERE ci.movie_id = t.id) AS actor_count
    FROM aka_title t
    JOIN kind_type mt ON t.kind_id = mt.id
    WHERE t.production_year >= 2000
)

SELECT md.title, 
       md.production_year, 
       md.movie_type, 
       COALESCE(mc.company_count, 0) AS company_count, 
       ah.actor_name,
       ah.level
FROM MovieDetails md
LEFT JOIN MovieCompanies mc ON md.movie_id = mc.movie_id
LEFT JOIN ActorHierarchy ah ON md.movie_id = ah.person_id
WHERE (md.actor_count > 5 OR mc.company_count IS NULL)
ORDER BY md.production_year DESC, md.title;
