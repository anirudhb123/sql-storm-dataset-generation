WITH RECURSIVE ActorHierarchy AS (
    SELECT c.person_id, a.name AS actor_name, 
           1 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.movie_id IN (
        SELECT movie_id 
        FROM aka_title 
        WHERE title LIKE '%Action%'
    )
    
    UNION ALL

    SELECT c.person_id, a.name AS actor_name, 
           ah.level + 1 
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN ActorHierarchy ah ON c.movie_id = ah.movie_id
    WHERE ah.level < 3
), 

MovieCompanies AS (
    SELECT mc.movie_id, STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),

ActionMovies AS (
    SELECT DISTINCT at.movie_id, at.title, at.production_year
    FROM aka_title at
    WHERE at.kind_id IN (
        SELECT id FROM kind_type WHERE kind = 'feature'
    )
    AND at.production_year >= 2000
),

TopMovies AS (
    SELECT am.title, am.production_year, 
           ROW_NUMBER() OVER (PARTITION BY am.production_year ORDER BY am.title) AS rn
    FROM ActionMovies am
    WHERE EXISTS (
        SELECT 1 
        FROM complete_cast cc
        WHERE cc.movie_id = am.movie_id 
        AND cc.status_id IS NULL
    )
)

SELECT tm.title, tm.production_year, 
       COALESCE(ch.actor_name, 'Unknown') AS lead_actor,
       mc.companies
FROM TopMovies tm
LEFT JOIN (SELECT ah.actor_name, c.movie_id
            FROM ActorHierarchy ah
            INNER JOIN cast_info c ON ah.person_id = c.person_id
            WHERE ah.level = 1) ch ON tm.movie_id = ch.movie_id
LEFT JOIN MovieCompanies mc ON tm.movie_id = mc.movie_id
ORDER BY tm.production_year DESC, tm.title;
