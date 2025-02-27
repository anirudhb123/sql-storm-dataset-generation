WITH 
RecursiveTitleCTE AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        t.kind_id,
        t.imdb_index,
        0 AS level
    FROM title t
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        t.kind_id,
        t.imdb_index,
        level + 1
    FROM title t
    JOIN RecursiveTitleCTE r ON r.kind_id = t.kind_id
    WHERE r.level < 3 -- Limit to max 3 recursion levels
),
FilteredMovies AS (
    SELECT 
        rt.title AS movie_title, 
        rt.production_year,
        rt.imdb_index,
        ROW_NUMBER() OVER (PARTITION BY rt.kind_id ORDER BY rt.production_year DESC) AS rn
    FROM RecursiveTitleCTE rt
    WHERE rt.production_year IS NOT NULL
),
ActorCTE AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        a.person_id, 
        COUNT(DISTINCT c.movie_id) AS films_count
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    GROUP BY a.id, a.name, a.person_id
)
SELECT 
    f.movie_title,
    f.production_year,
    a.actor_name,
    CASE 
        WHEN a.films_count IS NULL THEN 'No films'
        ELSE CAST(a.films_count AS VARCHAR)
    END AS films_count,
    CASE 
        WHEN f.production_year < 2010 THEN 'Older Movie'
        ELSE 'Recent Movie'
    END AS movie_age,
    COALESCE(k.keyword, 'No keywords') AS movie_keyword
FROM FilteredMovies f
LEFT JOIN ActorCTE a ON f.rn <= 3
LEFT JOIN movie_keyword mk ON mk.movie_id = f.movie_title
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE f.production_year IS NOT NULL
ORDER BY f.production_year DESC, a.actor_name
LIMIT 20;

-- This query generates a recursive common table expression to retrieve movie titles from 
-- the year 2000 onwards, filters out the movies while counting the associated actors 
-- and their films, and provides additional context about the movies’ ages and keywords,
-- demonstrating complex join logic, outer joins, window functions, and NULL handling.
