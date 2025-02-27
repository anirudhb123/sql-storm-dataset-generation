WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
), ActorMovieCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
), MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, '; ') AS info_list
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.keyword,
    amc.actor_count,
    mi.info_list
FROM 
    RankedTitles rt
JOIN 
    ActorMovieCounts amc ON rt.title_id = amc.movie_id
LEFT JOIN 
    MovieInfo mi ON rt.title_id = mi.movie_id
WHERE 
    rt.rn = 1 
ORDER BY 
    rt.production_year DESC, rt.title;