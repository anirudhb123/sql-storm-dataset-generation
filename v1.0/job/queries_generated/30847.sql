WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (SELECT movie_id FROM title WHERE production_year >= 2000)
    
    UNION ALL
    
    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id IN 
            (SELECT linked_movie_id FROM movie_link ml WHERE ml.movie_id = ah.movie_id)
),
RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS num_actors,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        COALESCE(mk.keywords, '{}') AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    CASE 
        WHEN rm.rank IS NOT NULL THEN rm.rank
        ELSE 'Not Ranked' 
    END AS actor_rank,
    CASE 
        WHEN md.keywords IS NOT NULL AND ARRAY_LENGTH(md.keywords, 1) > 0 THEN 
            STRING_AGG(md.keywords::text, ', ')
        ELSE 
            'No Keywords' 
    END AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    RankedMovies rm ON md.movie_id = rm.movie_id
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    actor_rank;
