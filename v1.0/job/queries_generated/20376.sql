WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn,
        COUNT(*) OVER (PARTITION BY m.production_year) AS total_movies
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS all_actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieStats AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_count,
        kc.keyword_count,
        (CASE 
            WHEN rm.rn = 1 THEN 'First in Year'
            WHEN cd.actor_count > 5 THEN 'Star-studded'
            ELSE 'Regular'
         END) AS movie_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        KeywordCounts kc ON rm.movie_id = kc.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.keyword_count,
    ms.movie_category,
    COALESCE(ms.actor_count, 0) AS effective_actor_count,
    CASE 
        WHEN ms.production_year < 2000 THEN 'Pre-2000'
        WHEN ms.production_year BETWEEN 2000 AND 2010 THEN '2000-2010'
        ELSE 'Post-2010'
    END AS release_epoch
FROM 
    MovieStats ms
WHERE 
    ms.actor_count IS NOT NULL
    AND ms.keyword_count > 0
ORDER BY 
    ms.production_year DESC, 
    ms.title ASC
LIMIT 50;

-- Additional complexity with UNION ALL to find distinct movie titles with and without keywords
UNION ALL

SELECT 
    DISTINCT at.title,
    at.production_year,
    NULL AS actor_count,
    NULL AS keyword_count,
    'No Keywords' AS movie_category,
    0 AS effective_actor_count,
    'Unknown Year' AS release_epoch
FROM 
    aka_title at
WHERE 
    at.id NOT IN (SELECT movie_id FROM movie_keyword)
ORDER BY 
    at.production_year DESC
LIMIT 50;
