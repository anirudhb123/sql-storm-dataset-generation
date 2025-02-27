WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
), 
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.production_year,
        m.title,
        mc.cast_count,
        mc.actors
    FROM movie_companies mc
    JOIN RankedTitles rt ON mc.movie_id = rt.title_id
    JOIN MovieCast m ON m.movie_id = mc.movie_id
    WHERE rt.title_rank <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.cast_count, 0) AS actor_count,
    CASE 
        WHEN fm.actor_count > 5 THEN 'Large Ensemble'
        WHEN fm.actor_count = 0 THEN 'No Cast'
        ELSE 'Regular Cast'
    END AS cast_category,
    fm.actors
FROM FilteredMovies fm
LEFT JOIN movie_info mi ON fm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
WHERE (fm.production_year >= 1990 AND fm.production_year <= 2023) 
  AND (mi.info IS NOT NULL OR fm.cast_count > 0)
ORDER BY fm.production_year DESC, fm.title;
