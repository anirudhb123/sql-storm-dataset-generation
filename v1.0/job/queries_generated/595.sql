WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(cc.id) DESC) AS movie_rank,
        COUNT(cc.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
PopularActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MovieKeywords AS (
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
    rm.title AS movie_title,
    rm.production_year,
    rk.person_id,
    pa.name AS actor_name,
    mk.keywords,
    rm.cast_count
FROM 
    RankedMovies rm
INNER JOIN 
    PopularActors pa ON rm.cast_count > 10
LEFT JOIN 
    cast_info ci ON ci.movie_id = rm.id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.id
WHERE 
    rm.movie_rank = 1
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 100;
