WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COALESCE(r.role, 'Unknown') AS role,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
DetailedMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        cd.actor_name,
        cd.actor_count,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = rt.title_id) AS keyword_count,
        (SELECT STRING_AGG(k.keyword, ', ') FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = rt.title_id) AS keywords
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CastDetails cd ON rt.title_id = cd.movie_id
)
SELECT 
    dm.title,
    dm.production_year,
    dm.actor_name,
    dm.actor_count,
    dm.keyword_count,
    dm.keywords,
    CASE 
        WHEN dm.actor_count > 5 THEN 'Ensemble Cast'
        WHEN dm.actor_count IS NULL THEN 'No Cast Info'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    DetailedMovies dm
WHERE 
    (dm.production_year = (SELECT MAX(production_year) FROM RankedTitles) OR dm.actor_name IS NOT NULL)
    AND dm.keyword_count > 0
ORDER BY 
    dm.production_year DESC,
    CAST(dm.title AS VARCHAR);
