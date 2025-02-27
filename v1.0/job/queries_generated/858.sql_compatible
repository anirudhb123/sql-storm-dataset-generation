
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
),
CastCount AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
ExtendedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(cc.actor_count, 0) AS actor_count,
        rm.rank_year
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        CastCount cc ON rm.movie_id = cc.movie_id
)
SELECT 
    em.movie_id,
    em.title,
    em.production_year,
    em.keywords,
    em.actor_count,
    CASE 
        WHEN em.actor_count > 10 THEN 'Large Cast'
        WHEN em.actor_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    ExtendedMovies em
WHERE 
    em.production_year BETWEEN 2000 AND 2023
    AND em.rank_year <= 5
ORDER BY 
    em.production_year DESC, em.title ASC;
