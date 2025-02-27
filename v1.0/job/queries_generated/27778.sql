WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names,
        rm.keywords,
        COALESCE(m.info, 'No info available') AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info m ON rm.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
)

SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.actor_names,
    md.keywords,
    md.movie_info
FROM 
    MovieDetails md
WHERE 
    md.cast_count >= 5 
ORDER BY 
    md.production_year DESC, md.cast_count DESC
LIMIT 10;
