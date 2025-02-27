WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) as keyword_rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(DISTINCT rm.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.keyword_rank <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
CastInfo AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    ci.cast_names
FROM 
    MovieDetails md
LEFT JOIN 
    CastInfo ci ON md.movie_id = ci.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title ASC;