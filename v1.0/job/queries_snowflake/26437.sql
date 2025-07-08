
WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank,
        at.id
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON ci.movie_id = at.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        at.production_year >= 2000
        AND ak.name IS NOT NULL
), 
MovieKeywords AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        RankedMovies rm
    JOIN 
        movie_keyword mk ON mk.movie_id = rm.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        rm.actor_rank <= 5 
    GROUP BY 
        rm.movie_title, rm.production_year
), 
MovieInfo AS (
    SELECT 
        mt.movie_title,
        mt.production_year,
        mi.info AS movie_info
    FROM 
        MovieKeywords mt
    JOIN 
        movie_info mi ON mi.movie_id = (
            SELECT id FROM aka_title 
            WHERE title = mt.movie_title AND production_year = mt.production_year 
            LIMIT 1
        )
)

SELECT 
    mi.movie_title,
    mi.production_year,
    mi.movie_info,
    mk.keywords
FROM 
    MovieInfo mi
JOIN 
    MovieKeywords mk ON mk.movie_title = mi.movie_title 
ORDER BY 
    mi.production_year DESC, 
    mi.movie_title ASC;
