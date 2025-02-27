WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM aka_title at
    WHERE at.production_year IS NOT NULL
),
TitleWithActors AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ak.name AS actor_name,
        COALESCE(CAST(COUNT(ci.id) AS INTEGER), 0) AS actor_count
    FROM RankedTitles rt
    LEFT JOIN cast_info ci ON ci.movie_id = rt.title_id
    LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
    GROUP BY rt.title_id, rt.title, rt.production_year, ak.name
),
FilteredTitles AS (
    SELECT 
        twat.title,
        twat.production_year,
        twat.actor_name,
        CASE 
            WHEN twat.actor_count > 5 THEN 'High Cast'
            WHEN twat.actor_count BETWEEN 3 AND 5 THEN 'Medium Cast'
            ELSE 'Low Cast'
        END AS cast_type
    FROM TitleWithActors twat
    WHERE twat.title IS NOT NULL AND twat.production_year BETWEEN 1990 AND 2000
)
SELECT 
    ft.title,
    ft.production_year,
    ft.actor_name,
    ft.cast_type,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id IN (SELECT tt.title_id FROM RankedTitles tt WHERE tt.production_year = ft.production_year)) AS keyword_count
FROM FilteredTitles ft
ORDER BY ft.production_year DESC, ft.title;
