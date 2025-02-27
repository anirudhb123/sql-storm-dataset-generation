WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.nr_order
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    INNER JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL

    UNION ALL

    SELECT 
        cah.cast_id,
        cah.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        cah.nr_order
    FROM 
        ActorHierarchy cah
    INNER JOIN 
        cast_info c ON cah.person_id = c.person_id
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    INNER JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        c.nr_order < 5  -- Assuming nr_order relates to some hierarchical depth
),

RankedMovies AS (
    SELECT 
        ah.actor_name,
        ah.movie_title,
        ah.production_year,
        ROW_NUMBER() OVER (PARTITION BY ah.actor_name ORDER BY ah.production_year DESC) AS movie_rank
    FROM 
        ActorHierarchy ah
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.actor_name,
    rm.movie_title,
    rm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mk.keywords IS NULL THEN 'No keywords found for this movie'
        ELSE 'Keywords available'
    END AS keyword_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.movie_rank <= 3
ORDER BY 
    rm.actor_name, rm.production_year DESC;

This query consists of multiple CTEs:

1. **ActorHierarchy**: A recursive CTE that forms a hierarchy of actors based on their roles.
2. **RankedMovies**: This CTE ranks the movies for each actor by the production year, helping to filter to the top 3 movies.
3. **MovieKeywords**: Collects all keywords associated with each movie into a single string for easy access.

Finally, it selects the actor names, their movies, years of production, and any associated keywords, providing a user-friendly message if keywords are absent. The outer query organizes this data by actor name and production year.
