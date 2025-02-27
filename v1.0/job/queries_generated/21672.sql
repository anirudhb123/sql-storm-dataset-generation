WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) as movies_count
    FROM 
        aka_title t 
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),

ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),

ExtendedMovieInfo AS (
    SELECT 
        rm.title,
        rm.production_year,
        ac.actor_count,
        COALESCE(mk.keyword, 'None') AS keyword,
        CASE 
            WHEN ci.note IS NULL THEN 'No note'
            ELSE ci.note 
        END AS cast_note
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.production_year = ac.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.production_year = mk.movie_id
    LEFT JOIN 
        movie_info mi ON rm.production_year = mi.movie_id
    LEFT JOIN 
        cast_info ci ON rm.production_year = ci.movie_id
)

SELECT 
    em.title,
    em.production_year,
    em.actor_count,
    em.keyword,
    em.cast_note,
    CASE 
        WHEN em.actor_count IS NULL THEN 'No Actors'
        WHEN em.actor_count = 0 THEN 'No Actors Present'
        ELSE CONCAT(em.actor_count, ' Actors')
    END AS actor_presence,
    CASE
        WHEN em.keyword IS NOT NULL THEN 'Keyword Exists'
        ELSE NULL 
    END AS keyword_status,
    ROUND(AVG(COALESCE(CAST(SUBSTRING(mi.info FROM '%[0-9]+') AS INTEGER), 0)), 2) AS average_info_value
FROM 
    ExtendedMovieInfo em
LEFT JOIN 
    movie_info mi ON em.title = mi.info
WHERE 
    (em.production_year > 2000 AND em.actor_count IS NOT NULL)
   OR (em.actor_count IS NULL AND em.keyword IS NULL)
GROUP BY 
    em.title, em.production_year, em.actor_count, em.keyword, em.cast_note
HAVING 
    MIN(em.actor_count) > 0 
ORDER BY 
    em.production_year DESC, em.title;
