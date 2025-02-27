WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC, COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actor_names,
        keywords
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.actor_names[1:3] AS top_3_actors,  
    fr.keywords
FROM 
    FilteredRankedMovies fr
ORDER BY 
    fr.production_year DESC, 
    fr.cast_count DESC
LIMIT 10;