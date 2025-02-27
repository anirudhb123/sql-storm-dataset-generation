WITH RECURSIVE ActorHirarchy AS (
    SELECT 
        ci.person_id,
        ct.kind AS role,
        1 AS level
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)

    UNION ALL

    SELECT 
        ci.person_id,
        ct.kind,
        ah.level + 1
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    JOIN ActorHirarchy ah ON ci.movie_id = ah.person_id 
    WHERE ah.level < 5
),
HighestRatedMovies AS (
    SELECT 
        at.title, 
        AVG(m.rating) AS avg_rating
    FROM aka_title at
    JOIN movie_info mi ON at.id = mi.movie_id 
    JOIN movie_rating m ON mi.movie_id = m.movie_id
    WHERE at.production_year >= 2000
    GROUP BY at.id
    HAVING AVG(m.rating) >= 8.0
),
CombinedData AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ah.role,
        COALESCE(hm.avg_rating, 0) AS avg_movie_rating
    FROM aka_name a
    LEFT JOIN ActorHirarchy ah ON a.person_id = ah.person_id
    LEFT JOIN HighestRatedMovies hm ON ah.movie_id = hm.movie_id
)

SELECT 
    actor_name,
    STRING_AGG(DISTINCT role, ', ') AS roles,
    COUNT(DISTINCT movie_id) AS movies_count,
    AVG(avg_movie_rating) AS avg_rating
FROM CombinedData
GROUP BY actor_name
ORDER BY avg_rating DESC
LIMIT 10;
