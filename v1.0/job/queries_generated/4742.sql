WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
FullMovieDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ac.actor_count,
        (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = c.movie_id) AS keywords
    FROM 
        RankedTitles rt
    LEFT JOIN 
        full_cast fc ON rt.title_id = fc.movie_id
    LEFT JOIN 
        ActorCount ac ON rt.title_id = ac.movie_id
)
SELECT 
    fmd.title,
    fmd.production_year,
    COALESCE(fmd.actor_count, 0) AS total_actors,
    COALESCE(fmd.keywords, 'No Keywords') AS keywords
FROM 
    FullMovieDetails fmd
WHERE 
    fmd.actor_count IS NOT NULL OR fmd.keywords IS NOT NULL
ORDER BY 
    fmd.production_year DESC, fmd.title;
