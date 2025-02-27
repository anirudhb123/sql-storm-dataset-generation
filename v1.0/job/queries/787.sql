WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
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
    JOIN 
        person_info pi ON ci.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'directors')
    GROUP BY 
        ci.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ac.actor_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN ac.actor_count > 10 THEN 'Ensemble Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN rm.year_rank <= 5 THEN 'Top Movies of Year'
        ELSE 'Other Movies'
    END AS movie_category
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MoviesWithKeywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, rm.title;
