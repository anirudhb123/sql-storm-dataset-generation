WITH RECURSIVE CastHierarchy AS (
    SELECT c.person_id, c.movie_id, 1 AS depth, 
           COALESCE(a.name, 'Unknown') AS actor_name,
           COALESCE(t.title, 'Untitled') AS movie_title,
           COALESCE(t.production_year, 0) AS production_year
    FROM cast_info c
    LEFT JOIN aka_name a ON c.person_id = a.person_id 
    LEFT JOIN aka_title t ON c.movie_id = t.movie_id 
    WHERE t.production_year IS NOT NULL
   
    UNION ALL

    SELECT c.person_id, c.movie_id, ch.depth + 1,
           COALESCE(a.name, 'Unknown') AS actor_name,
           COALESCE(t.title, 'Untitled') AS movie_title,
           COALESCE(t.production_year, 0) AS production_year 
    FROM cast_info c
    JOIN CastHierarchy ch ON c.movie_id = ch.movie_id AND c.person_id != ch.person_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id 
    LEFT JOIN aka_title t ON c.movie_id = t.movie_id 
    WHERE t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT ch.movie_id, ch.movie_title, ch.production_year, COUNT(DISTINCT ch.person_id) AS actor_count
    FROM CastHierarchy ch
    GROUP BY ch.movie_id, ch.movie_title, ch.production_year
    HAVING COUNT(DISTINCT ch.person_id) > 2
),
RankedMovies AS (
    SELECT *, 
           RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank_in_year
    FROM FilteredMovies
)
SELECT fm.movie_id, fm.movie_title, fm.production_year, fm.actor_count
FROM RankedMovies fm
WHERE fm.rank_in_year <= 5
AND EXISTS (
    SELECT 1 
    FROM movie_info mi 
    WHERE mi.movie_id = fm.movie_id AND mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Box Office'
    ) AND mi.info IS NOT NULL
)
ORDER BY fm.production_year DESC, fm.actor_count DESC;