WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rn
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year >= 2000
        AND ak.name IS NOT NULL 
    GROUP BY 
        mt.id, mt.title, mt.production_year, ak.name
),
MovieDetails AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        ARRAY_AGG(DISTINCT rm.actor_name) AS actors,
        rm.company_count,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn = 1
    GROUP BY 
        rm.movie_title, rm.production_year, rm.company_count, rm.keyword_count
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actors,
    md.company_count,
    md.keyword_count
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.company_count DESC, 
    md.keyword_count DESC
LIMIT 10;
