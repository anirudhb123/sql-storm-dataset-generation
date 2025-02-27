WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON ah.person_id = ci.person_id
    WHERE 
        ci.movie_id IS NOT NULL
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    COALESCE(kd.keyword_count, 0) AS keyword_count,
    ah.actor_name AS top_actor
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordDetails kd ON md.movie_id = kd.movie_id
LEFT JOIN 
    ActorHierarchy ah ON md.actor_count = (SELECT MAX(actor_count) FROM MovieDetails WHERE production_year = md.production_year)
WHERE 
    md.actor_count > 10
ORDER BY 
    md.production_year DESC, md.actor_count DESC
LIMIT 10;

### Explanation:
1. **ActorHierarchy CTE**: This recursive CTE helps to build a hierarchy of actors working in movies. It retrieves actors from `cast_info` and `aka_name`.
   
2. **MovieDetails CTE**: This aggregates movie details, counting distinct actors for each movie, and concatenating actor names into a single string using `STRING_AGG`.

3. **KeywordDetails CTE**: Counts distinct keywords associated with each movie to add a richness of information.

4. **Final SELECT**: Retrieves selected movie details joined with keyword counts and the top actor based on the number of actors involved in the specified production year. It filters out movies that have fewer than 10 actors and orders by production year and actor count, limiting the final result to 10 rows.
