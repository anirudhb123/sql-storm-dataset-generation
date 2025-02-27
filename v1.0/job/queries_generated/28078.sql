WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),

MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(DISTINCT rm.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),

MovieCast AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        complete_cast m
    JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        m.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    mc.cast_count,
    mc.cast_names
FROM 
    MovieDetails md
JOIN 
    MovieCast mc ON md.movie_id = mc.movie_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC,
    mc.cast_count DESC
LIMIT 20;
