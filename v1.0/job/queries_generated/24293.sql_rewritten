WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
KeywordCounts AS (
    SELECT 
        mk.movie_id, 
        COUNT(k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count,
        kc.keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        KeywordCounts kc ON rm.movie_id = kc.movie_id
    WHERE 
        rm.total_movies > 5
        AND (ac.actor_count IS NULL OR ac.actor_count >= 5) 
)
SELECT
    fm.title,
    fm.production_year,
    COALESCE(fm.actor_count, 0) AS actor_count,
    COALESCE(fm.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN fm.actor_count IS NOT NULL THEN 'Actor information available'
        ELSE 'No actors found'
    END AS actor_info_status,
    CASE 
        WHEN fm.keyword_count IS NULL THEN 'No keywords associated'
        ELSE 'Keywords are present'
    END AS keyword_info_status
FROM 
    FilteredMovies fm
WHERE 
    fm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    fm.production_year DESC, fm.title;