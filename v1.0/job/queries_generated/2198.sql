WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
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
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        md.actors,
        md.keywords,
        RANK() OVER (ORDER BY md.actor_count DESC) AS rank_by_actors
    FROM 
        MovieDetails md
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actors,
    rm.keywords,
    COALESCE(n.info, 'No additional info') AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_info mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    info_type n ON mi.info_type_id = n.id
WHERE 
    rm.rank_by_actors <= 10
    AND (n.info IS NULL OR n.info LIKE '%Award%')
ORDER BY 
    rm.rank_by_actors;
