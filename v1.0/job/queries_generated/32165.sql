WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        a.person_id,
        a.movie_count,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.movie_count DESC) AS rn
    FROM 
        ActorHierarchy a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
)
SELECT 
    an.name AS actor_name,
    COALESCE(tm.title, 'No Movies') AS movie_title,
    COALESCE(tm.production_year, NULL) AS production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    aka_name an
LEFT JOIN 
    TopMovies tm ON an.id = tm.person_id AND tm.rn <= 5
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.movie_id
WHERE 
    an.md5sum IS NOT NULL
ORDER BY 
    an.actor_name, tm.production_year DESC;

This SQL query includes:

1. Recursive Common Table Expressions (CTEs) to build an actor hierarchy based on the number of movies.
2. A second CTE to aggregate keywords for each movie.
3. A third CTE to select the top movies for each actor based on the movie count.
4. The main query retrieves actor names, titles, and production years using LEFT JOINs, applying COALESCE functions for NULL handling.
5. Utilizes the `STRING_AGG` function to concatenate movie keywords.
6. Implements window functions to rank movies for each actor.
