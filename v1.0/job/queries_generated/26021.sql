WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        COALESCE(SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS info_type_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
ActorRankings AS (
    SELECT 
        movie_id,
        actor_names,
        ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    rm.info_type_count,
    rm.keywords,
    ar.rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRankings ar ON rm.movie_id = ar.movie_id AND ar.rank = 1
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC, 
    rm.title;
