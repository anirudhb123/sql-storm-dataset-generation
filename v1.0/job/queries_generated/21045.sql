WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT c.id) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(am.actor_count, 0) AS actor_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN ActorMovies am ON rm.movie_id = am.movie_id
    LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.rn = 1 -- Only get the first movie for each year
),
FinalSelection AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.actor_count,
        fm.keywords,
        CASE 
            WHEN fm.actor_count > 5 THEN 'Popular'
            WHEN fm.actor_count BETWEEN 2 AND 5 THEN 'Moderate'
            ELSE 'Unknown'
        END AS popularity_status
    FROM 
        FilteredMovies fm
    WHERE 
        fm.production_year BETWEEN 2000 AND 2023
        AND fm.keywords NOT LIKE '%Comedy%'
)

SELECT 
    fs.title,
    fs.production_year,
    fs.actor_count,
    fs.keywords,
    fs.popularity_status,
    COUNT(*) OVER () AS total_movies,
    MAX(CASE WHEN fs.actor_count IS NULL THEN 0 ELSE fs.actor_count END) OVER () AS max_actor_count
FROM 
    FinalSelection fs
ORDER BY 
    fs.production_year DESC, fs.title;
