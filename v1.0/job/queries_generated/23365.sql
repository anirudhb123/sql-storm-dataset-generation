WITH Recursive_CTE AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        COALESCE(t.production_year, 0) AS production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COALESCE(t.production_year, 0) DESC) AS rn
    FROM aka_name a
    LEFT JOIN cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN aka_title t ON ci.movie_id = t.movie_id
    WHERE a.name IS NOT NULL OR a.md5sum IS NOT NULL
), 
Filtered_CTE AS (
    SELECT
        actor_id,
        actor_name,
        production_year
    FROM Recursive_CTE
    WHERE production_year >= 2000
), 
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        production_year,
        CASE 
            WHEN production_year = 0 THEN 'Unknown Year'
            ELSE 'Known Year'
        END AS year_status
    FROM Filtered_CTE
    WHERE rn <= 10
)
SELECT 
    ta.actor_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    SUM(CASE WHEN ci.note LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles,
    STRING_AGG(DISTINCT t.title, ', ') AS movies
FROM TopActors ta
LEFT JOIN cast_info ci ON ta.actor_id = ci.person_id
LEFT JOIN aka_title t ON ci.movie_id = t.movie_id
WHERE ci.role_id IS NULL OR ci.nr_order IS NOT NULL
GROUP BY ta.actor_name
HAVING COUNT(DISTINCT ci.movie_id) > 5
UNION ALL
SELECT 
    'No Movie Found' AS actor_name,
    0 AS movie_count,
    0 AS lead_roles,
    STRING_AGG(NULLIF(t.title, ''), ', ') AS movies
FROM aka_name a
LEFT JOIN cast_info ci ON a.person_id = ci.person_id
LEFT JOIN aka_title t ON ci.movie_id = t.movie_id
WHERE t.title IS NULL 
GROUP BY a.name
HAVING COUNT(DISTINCT ci.movie_id) = 0
ORDER BY movie_count DESC, actor_name;
