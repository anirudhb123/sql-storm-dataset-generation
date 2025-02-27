WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND k.keyword IS NOT NULL
),
CompleteCast AS (
    SELECT
        cc.movie_id,
        STRING_AGG(CONCAT(ak.name, ' as ', rt.role), ', ') AS full_cast
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON rt.id = ci.role_id
    GROUP BY 
        cc.movie_id
),
MovieDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rc.full_cast,
        rm.keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompleteCast rc ON rm.movie_id = rc.movie_id
    WHERE 
        rm.rank_per_year <= 5 -- Top 5 movies per year for performance benchmarking
)

SELECT 
    md.title,
    md.production_year,
    md.full_cast,
    md.keyword
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title
LIMIT 100; -- Limiting results for efficiency while benchmarking
