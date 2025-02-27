WITH RECURSIVE ActorHierarchy AS (
    SELECT
        ci.person_id,
        t.title,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS actor_order
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    WHERE ci.nr_order IS NOT NULL
),
TopPerformingActors AS (
    SELECT
        a.person_id,
        COUNT(DISTINCT a.title) AS movie_count,
        MIN(a.nr_order) AS lowest_order,
        AVG(a.nr_order) AS average_order
    FROM ActorHierarchy a
    GROUP BY a.person_id
    HAVING AVG(a.nr_order) < 5  -- Adjust as needed to filter top performers
),
ActorNames AS (
    SELECT
        an.person_id,
        STRING_AGG(an.name, ', ') AS full_name
    FROM aka_name an
    JOIN TopPerformingActors t ON an.person_id = t.person_id
    GROUP BY an.person_id
),
MovieDetails AS (
    SELECT
        t.title,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        SUM(mc.note IS NOT NULL) AS company_notes
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.title
    HAVING COUNT(DISTINCT k.keyword) > 1
)
SELECT
    an.full_name,
    t.title,
    t.movie_count,
    t.lowest_order,
    t.average_order,
    md.keyword_count,
    md.company_notes
FROM TopPerformingActors t
JOIN ActorNames an ON t.person_id = an.person_id
JOIN MovieDetails md ON md.keyword_count > 2
ORDER BY t.average_order DESC, md.company_notes ASC
LIMIT 10;

-- Additionally checking for NULL logic
SELECT 
    a.person_id,
    COUNT(NOT EXISTS (
        SELECT 1
        FROM cast_info ci
        WHERE ci.person_id = a.person_id
        AND ci.note IS NULL
    )) AS has_notes
FROM aka_name an
JOIN cast_info a ON an.person_id = a.person_id
WHERE an.name IS NOT NULL
GROUP BY a.person_id
HAVING has_notes = 0;  -- Find actors with no notes
