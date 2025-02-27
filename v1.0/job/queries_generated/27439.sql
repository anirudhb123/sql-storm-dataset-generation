WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info c ON mc.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        actor_count DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_count,
        rm.actor_names,
        COALESCE(mi.info, 'No additional info') AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id 
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_count,
    md.actor_names,
    md.additional_info
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC;
