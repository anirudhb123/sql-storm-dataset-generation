WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        at.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    GROUP BY 
        at.id
),
MovieInfo AS (
    SELECT 
        at.id AS movie_id,
        STRING_AGG(mi.info, '; ') AS information
    FROM 
        aka_title at
    LEFT JOIN 
        movie_info mi ON at.id = mi.movie_id
    GROUP BY 
        at.id
)
SELECT 
    m.movie_title,
    m.production_year,
    m.actor_name,
    m.keywords,
    mi.information
FROM 
    RankedMovies m
JOIN 
    MovieKeywords mk ON m.id = mk.movie_id
JOIN 
    MovieInfo mi ON m.id = mi.movie_id
WHERE 
    m.actor_rank <= 3
ORDER BY 
    m.production_year DESC, 
    m.actor_name;
