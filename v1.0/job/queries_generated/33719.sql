WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.person_id,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        1 AS level
    FROM 
        cast_info ca
    LEFT JOIN 
        aka_name a ON ca.person_id = a.person_id
    WHERE 
        ca.movie_id IN (SELECT id FROM aka_title WHERE production_year > 2000)
    UNION ALL
    SELECT 
        ca.person_id,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        level + 1
    FROM 
        cast_info ca
    JOIN 
        ActorHierarchy ah ON ca.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id)
    LEFT JOIN 
        aka_name a ON ca.person_id = a.person_id
    WHERE 
        level < 5
), MovieDetails AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        STRING_AGG(DISTINCT COALESCE(ac.actor_name, 'Unknown Actor'), ', ') AS cast_list
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ca ON at.id = ca.movie_id
    LEFT JOIN 
        aka_name ac ON ca.person_id = ac.person_id
    GROUP BY 
        at.id, at.title, at.production_year
), MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_list,
    COALESCE(mg.genres, 'No genres') AS genres,
    ah.actor_name AS prominent_actor,
    ah.level
FROM 
    MovieDetails md
LEFT JOIN 
    MovieGenres mg ON md.movie_id = mg.movie_id
LEFT JOIN 
    ActorHierarchy ah ON md.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id)
WHERE 
    md.production_year = (
        SELECT 
            MAX(production_year) 
        FROM 
            aka_title
        WHERE 
            title ILIKE '%action%'
    )
ORDER BY 
    md.total_cast DESC
LIMIT 10;
