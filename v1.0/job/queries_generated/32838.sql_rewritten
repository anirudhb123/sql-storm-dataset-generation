WITH RECURSIVE ActorHierarchy AS (
    SELECT c.person_id, a.name AS actor_name, 
           CAST(1 AS INTEGER) AS depth
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.movie_id IN (
        SELECT id 
        FROM aka_title 
        WHERE title ILIKE '%Avengers%'
    )
    
    UNION ALL
    
    SELECT c2.person_id, a2.name AS actor_name, 
           ah.depth + 1
    FROM ActorHierarchy ah
    JOIN cast_info c2 ON ah.person_id = c2.person_id
    JOIN aka_name a2 ON c2.person_id = a2.person_id
    WHERE c2.movie_id IN (
        SELECT linked_movie_id 
        FROM movie_link 
        WHERE movie_id IN (
            SELECT id 
            FROM aka_title 
            WHERE title ILIKE '%Avengers%'
        )
    )
),
MovieOverview AS (
    SELECT t.title, t.production_year, COUNT(DISTINCT ci.person_id) AS total_actors,
           STRING_AGG(DISTINCT a.name, ', ') AS actors_list
    FROM aka_title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    WHERE t.production_year > 2000
    GROUP BY t.title, t.production_year
),
ActorSummary AS (
    SELECT actor_name, COUNT(*) AS movie_count
    FROM ActorHierarchy
    GROUP BY actor_name
    HAVING COUNT(*) > 1  
)
SELECT mo.title, mo.production_year, mo.total_actors, 
       mo.actors_list, 
       asu.actor_name, asu.movie_count
FROM MovieOverview mo
JOIN ActorSummary asu ON mo.actors_list LIKE '%' || asu.actor_name || '%'
WHERE mo.total_actors > 5
ORDER BY mo.production_year DESC, mo.title;