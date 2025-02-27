WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_year
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
MovieDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    COALESCE(kd.keywords, 'No keywords') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordDetails kd ON md.movie_id = kd.movie_id
WHERE 
    md.actor_count > 0
ORDER BY 
    md.production_year DESC, md.title ASC;
