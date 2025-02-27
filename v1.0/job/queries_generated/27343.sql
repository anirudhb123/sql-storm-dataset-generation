WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        title t
    JOIN 
        aka_title ak ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = rm.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, rm.cast_count, rm.actor_names
),
HighCastMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        MoviesWithKeywords
)
SELECT 
    hcm.movie_title,
    hcm.production_year,
    hcm.cast_count,
    hcm.actor_names,
    hcm.keywords
FROM 
    HighCastMovies hcm
WHERE 
    hcm.rank <= 5
ORDER BY 
    hcm.production_year DESC, hcm.cast_count DESC;
