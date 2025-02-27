WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        ac.actor_count
    FROM RankedMovies rm
    LEFT JOIN ActorCounts ac ON rm.movie_id = ac.movie_id
    WHERE ac.actor_count > 5 OR ac.actor_count IS NULL
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.actor_count, 0) AS actor_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    MAX(COALESCE(mi.info, 'No Info')) AS additional_info
FROM FilteredMovies fm
LEFT JOIN cast_info ci ON fm.movie_id = ci.movie_id
LEFT JOIN aka_name a ON ci.person_id = a.person_id
LEFT JOIN movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_info mi ON fm.movie_id = mi.movie_id
WHERE fm.production_year > 2000
GROUP BY fm.movie_id, fm.title, fm.production_year
ORDER BY fm.production_year DESC, actor_count DESC;
