WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        MAX(CASE WHEN i.info_type_id = 1 THEN i.info END) AS genre,
        MAX(CASE WHEN i.info_type_id = 2 THEN i.info END) AS language
    FROM 
        title m
    LEFT JOIN 
        movie_info i ON m.id = i.movie_id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    d.title,
    d.production_year,
    d.cast_count,
    d.actor_names,
    rt.title_rank,
    COALESCE(d.genre, 'Unknown') AS genre,
    COALESCE(d.language, 'Not Specified') AS language
FROM 
    MovieDetails d
JOIN 
    RankedTitles rt ON d.movie_id = rt.title_id
WHERE 
    d.cast_count > 0
ORDER BY 
    d.production_year DESC, rt.title_rank
LIMIT 10;
