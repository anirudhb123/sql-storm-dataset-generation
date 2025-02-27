WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND ak.name IS NOT NULL
),
GenreKeywords AS (
    SELECT 
        mt.id AS movie_id,
        k.keyword
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        GROUP_CONCAT(DISTINCT mi.info) AS info_details
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        m.id
)

SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.actor_name,
    GROUP_CONCAT(DISTINCT gk.keyword) AS genres,
    mi.info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    GenreKeywords gk ON rm.movie_id = gk.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 5
GROUP BY 
    rm.rank, rm.title, rm.production_year, rm.actor_name, mi.info_details
ORDER BY 
    rm.production_year DESC, rm.rank;
