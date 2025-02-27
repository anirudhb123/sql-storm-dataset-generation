
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 1990 AND 2000
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
FilmStatistics AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        CASE 
            WHEN COALESCE(ac.actor_count, 0) < 10 THEN 'Few Actors'
            WHEN COALESCE(ac.actor_count, 0) BETWEEN 10 AND 20 THEN 'Moderate'
            ELSE 'Many Actors'
        END AS actor_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        fs.movie_id,
        fs.title,
        fs.production_year,
        fs.actor_category,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        FilmStatistics fs
    LEFT JOIN 
        movie_keyword mk ON fs.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        fs.movie_id, fs.title, fs.production_year, fs.actor_category
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.actor_category,
    mwk.keywords,
    CASE 
        WHEN mwk.production_year IS NULL THEN 'No Year Provided'
        ELSE CAST(mwk.production_year AS text)
    END AS year_info
FROM 
    MoviesWithKeywords mwk
WHERE 
    mwk.actor_category <> 'Few Actors'
ORDER BY 
    mwk.production_year DESC, mwk.title;
