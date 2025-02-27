WITH MovieDetails AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN LENGTH(c.note) > 10 THEN 1 ELSE 0 END) AS avg_long_notes
    FROM 
        aka_title at
    JOIN 
        cast_info c ON at.movie_id = c.movie_id
    GROUP BY 
        at.title, at.production_year
),
ActorInformation AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
FilteredMovieLinks AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        lt.link AS link_type
    FROM 
        movie_link ml
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
    WHERE 
        lt.link LIKE 'Related%'
)

SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    ai.actor_name,
    ai.movie_count,
    fml.linked_movie_id,
    fml.link_type
FROM 
    MovieDetails md
LEFT JOIN 
    ActorInformation ai ON md.actor_count > 10
LEFT JOIN 
    FilteredMovieLinks fml ON md.title ILIKE 'The%'
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, md.actor_count DESC
LIMIT 100;

