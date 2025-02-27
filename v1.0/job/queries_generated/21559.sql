WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id DESC) AS rank_per_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MoviesWithActors AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.kind_id,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.id = ac.movie_id
),
RecentMovies AS (
    SELECT 
        mw.title,
        mw.production_year,
        mw.actor_count,
        CASE 
            WHEN mw.actor_count = 0 THEN 'No Actors'
            WHEN mw.actor_count < 5 THEN 'Few Actors'
            ELSE 'Many Actors'
        END AS actor_group
    FROM 
        MoviesWithActors mw
    WHERE 
        mw.production_year >= 2000
),
KeywordAssociations AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
FinalOutput AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        ra.actor_group,
        ka.keywords
    FROM 
        RecentMovies ra
    LEFT JOIN 
        KeywordAssociations ka ON ra.title = (SELECT title FROM aka_title WHERE id IN (SELECT movie_id FROM movie_keyword WHERE movie_id IN (SELECT movie_id FROM movie_link WHERE linked_movie_id IN (SELECT id FROM aka_title WHERE title = ra.title))))
)
SELECT 
    fo.title,
    fo.production_year,
    fo.actor_count,
    fo.actor_group,
    COALESCE(fo.keywords, 'No Keywords Available') AS keywords,
    CASE 
        WHEN fo.actor_count IS NULL THEN 'Actor count is not available'
        WHEN fo.actor_count > 10 AND fo.production_year < 2010 THEN 'Blockbuster Era!'
        ELSE 'Not a Blockbuster!'
    END AS classification
FROM 
    FinalOutput fo
WHERE 
    fo.actor_group <> 'No Actors'
ORDER BY 
    fo.production_year DESC, 
    fo.actor_count DESC;
