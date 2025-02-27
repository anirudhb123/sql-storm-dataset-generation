WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
    ORDER BY 
        actor_count DESC
    LIMIT 10
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        rm.movie_id,
        rm.title
    FROM 
        RankedMovies rm
    JOIN 
        cast_info ci ON ci.movie_id = rm.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
),
MovieInfo AS (
    SELECT 
        rm.movie_id,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT mi.info, '; ') AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = rm.movie_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = rm.movie_id
    GROUP BY 
        rm.movie_id
)
SELECT 
    ad.actor_name,
    ad.title,
    ad.movie_id,
    mi.keywords,
    mi.movie_info
FROM 
    ActorDetails ad
JOIN 
    MovieInfo mi ON mi.movie_id = ad.movie_id
ORDER BY 
    ad.title, ad.actor_name;
