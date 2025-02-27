WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_list
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        md.actors_list,
        RANK() OVER (ORDER BY md.actor_count DESC) AS actor_rank
    FROM 
        MovieDetails md
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actors_list,
    CASE 
        WHEN rm.actor_count IS NULL THEN 'No Actors'
        WHEN rm.actor_count > 5 THEN 'Blockbuster'
        ELSE 'Independent'
    END AS movie_category
FROM 
    RankedMovies rm
WHERE 
    rm.actor_rank <= 10
ORDER BY 
    rm.actor_rank;
