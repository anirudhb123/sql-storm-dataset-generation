
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfoData AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Plot' THEN mi.info END) AS plot_summary,
        MAX(CASE WHEN it.info = 'Genre' THEN mi.info END) AS genre
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(mk.keywords, 'None') AS keywords,
    COALESCE(mid.plot_summary, 'No summary available') AS plot,
    COALESCE(mid.genre, 'Unknown genre') AS genre,
    CASE 
        WHEN rm.rn = 1 THEN 'First Movie of Year'
        WHEN rm.rn = rm.total_movies THEN 'Last Movie of Year'
        ELSE 'Intermediate Movie of Year'
    END AS movie_position
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfoData mid ON rm.movie_id = mid.movie_id
WHERE 
    (rm.production_year > 2000 AND COALESCE(ac.actor_count, 0) > 5)
    OR (rm.production_year <= 2000 AND mid.genre IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.title;
