WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(a.name, 'Unknown') AS actor_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title m ON c.movie_id = m.id
    GROUP BY 
        m.id, a.name
),
TotalMovieInfo AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    JOIN 
        title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rt.movie_title,
    rt.production_year,
    mc.actor_name,
    mc.role_count,
    tm.keyword_count,
    tm.info_count
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieCast mc ON rt.production_year = mc.movie_id
LEFT JOIN 
    TotalMovieInfo tm ON mc.movie_id = tm.movie_id
WHERE 
    rt.year_rank <= 10 AND
    (tm.keyword_count > 0 OR tm.info_count > 0)
ORDER BY 
    rt.production_year DESC, mc.role_count DESC
LIMIT 50;
