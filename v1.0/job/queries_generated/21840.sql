WITH RECURSIVE ActorHierarchy AS (
    SELECT
        ci.person_id,
        t.title,
        ct.kind AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS rn,
        COALESCE(t.production_year, 0) AS prod_year,
        COALESCE(t.note, 'No note') AS note
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE t.production_year IS NOT NULL

    UNION ALL

    SELECT
        ah.person_id,
        t.title,
        ct.kind AS role,
        ROW_NUMBER() OVER (PARTITION BY ah.person_id ORDER BY t.production_year DESC) AS rn,
        COALESCE(t.production_year, 0) AS prod_year,
        COALESCE(t.note, 'No note') AS note
    FROM ActorHierarchy ah
    JOIN movie_link ml ON ah.prod_year = ml.linked_movie_id
    JOIN title t ON ml.movie_id = t.id
    JOIN comp_cast_type ct ON ah.role_id = ct.id
    WHERE ah.rn < 5
)

SELECT
    ak.id AS actor_id,
    ak.name AS actor_name,
    STRING_AGG(DISTINCT ah.title, ', ') AS movies,
    MAX(ah.prod_year) AS last_movie_year,
    COUNT(DISTINCT ah.note) AS distinct_notes,
    COUNT(DISTINCT CASE WHEN ah.note IS NULL THEN 'Null Note' END) AS null_notes_count
FROM aka_name ak
LEFT JOIN ActorHierarchy ah ON ak.person_id = ah.person_id
GROUP BY ak.id, ak.name
HAVING COUNT(DISTINCT ah.title) > 1
   OR MAX(ah.prod_year) < (SELECT AVG(prod_year) FROM ActorHierarchy)
ORDER BY last_movie_year DESC;

-- This query benchmarks the performance of complex operations on actors, titles, and their connections,
-- employing CTEs, window functions, aggregate functions, joining, and null handling to ensure a rich result set.
