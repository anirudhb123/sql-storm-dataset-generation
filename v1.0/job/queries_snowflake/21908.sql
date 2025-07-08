
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mt.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS year_count
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
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
PremiereMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title,
        rm.production_year,
        CASE 
            WHEN rm.year_count > 1 THEN 'Multiple Entries'
            ELSE 'Unique Entry'
        END AS entry_type,
        ac.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
),
FilteredMovies AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.production_year,
        pm.entry_type,
        pm.actor_count,
        COALESCE(pm.actor_count, 0) AS safe_actor_count
    FROM 
        PremiereMovies pm
    WHERE 
        pm.production_year >= 2000 
        AND (pm.actor_count IS NULL OR pm.actor_count > 5)
),
KeywordSearch AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.entry_type,
    fm.safe_actor_count,
    ks.keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    KeywordSearch ks ON fm.movie_id = ks.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.title,
    CASE 
        WHEN ks.keywords IS NULL THEN 1
        ELSE 0 
    END,
    fm.safe_actor_count DESC;
