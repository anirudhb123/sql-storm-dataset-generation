
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv'))
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
DetailedMovieInfo AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mi.id) AS info_count,
        STRING_AGG(DISTINCT mi.info, ', ') AS additional_info
    FROM 
        movie_info mi
    JOIN 
        movie_companies mc ON mc.movie_id = mi.movie_id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    am.actor_name,
    am.actor_count,
    dmi.info_count,
    dmi.additional_info
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorMovies am ON rt.title_id = am.movie_id
LEFT JOIN 
    DetailedMovieInfo dmi ON dmi.movie_id = rt.title_id
WHERE 
    rt.title_rank = 1 AND
    (am.actor_name IS NOT NULL OR dmi.info_count > 0)
ORDER BY 
    rt.production_year DESC, 
    rt.title;
