WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

ActorsWithTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ARRAY_AGG(DISTINCT at.title) AS titles,
        COUNT(DISTINCT at.title) AS title_count
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    INNER JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    GROUP BY 
        a.id, a.name
),

MoviesWithInfo AS (
    SELECT 
        mt.movie_id,
        mt.info,
        COALESCE(mt.note, 'No Note') AS note_info,
        ROW_NUMBER() OVER (PARTITION BY mt.movie_id ORDER BY mi.id DESC) AS row_num
    FROM 
        movie_info mt
    LEFT JOIN 
        movie_info_idx mi ON mt.movie_id = mi.movie_id
    WHERE 
        mt.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Awards%')
)

SELECT
    at.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    awt.title_count AS actor_title_count,
    mw.info AS movie_info,
    mw.note_info,
    CASE 
        WHEN awt.title_count > 5 THEN 'Prolific Actor'
        ELSE 'Emerging Actor'
    END AS actor_status
FROM 
    RankedTitles rt
INNER JOIN 
    ActorsWithTitles awt ON rt.title = ANY(awt.titles)
LEFT JOIN 
    MoviesWithInfo mw ON rt.id = mw.movie_id
WHERE 
    rt.title_rank <= 3 
    AND rt.production_year >= 2000
ORDER BY 
    rt.production_year DESC, awt.title_count DESC;
