WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title m
    JOIN 
        cast_info c ON c.movie_id = m.id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        m.production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, '; ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON it.id = mi.info_type_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_name,
    rm.actor_rank,
    mk.keywords,
    mi.info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.movie_id
LEFT JOIN 
    MovieInfo mi ON mi.movie_id = rm.movie_id
WHERE 
    rm.actor_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.movie_id;
