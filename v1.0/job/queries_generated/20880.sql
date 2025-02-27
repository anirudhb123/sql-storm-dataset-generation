WITH actor_movies AS (
    SELECT 
        c.person_id AS actor_id, 
        t.title AS movie_title, 
        t.imdb_index AS movie_imdb_index, 
        COUNT(c.movie_id) OVER (PARTITION BY c.person_id) AS total_movies,
        STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
        MAX(t.production_year) OVER (PARTITION BY c.person_id) AS last_movie_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS year_rank,
        CASE 
            WHEN MAX(t.production_year) OVER (PARTITION BY c.person_id) > 2020 THEN 'Recent'
            WHEN MAX(t.production_year) OVER (PARTITION BY c.person_id) <= 2000 THEN 'Classic'
            ELSE 'Modern'
        END AS movie_category
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        ak.name IS NOT NULL
),

recent_movies AS (
    SELECT 
        movie_title, 
        actor_id
    FROM 
        actor_movies
    WHERE 
        year_rank = 1 -- Select only the most recent movie for each actor
),

actors_with_no_movies AS (
    SELECT 
        p.id AS person_id,
        ak.name AS actor_name
    FROM 
        name p
    LEFT JOIN 
        aka_name ak ON p.id = ak.person_id
    LEFT JOIN 
        cast_info c ON c.person_id = p.id
    WHERE 
        c.movie_id IS NULL AND ak.name IS NOT NULL
)

SELECT 
    DISTINCT a.actor_name,
    COALESCE(r.movie_title, 'No Recent Movies') AS recent_movie,
    a.total_movies,
    a.keywords,
    a.last_movie_year,
    a.movie_category
FROM 
    actor_movies a
FULL OUTER JOIN 
    recent_movies r ON a.actor_id = r.actor_id
LEFT JOIN 
    actors_with_no_movies no_movies ON a.actor_id = no_movies.person_id
ORDER BY 
    a.last_movie_year DESC NULLS LAST, 
    a.actor_name ASC;

This SQL query includes several complex constructs:
1. Common Table Expressions (CTEs) to aggregate actor movie data, filter for actors with no movies, and recent movie selections.
2. A combination of traditional JOINs and FULL OUTER JOINs to ensure inclusion of all actors, even those without movies.
3. Window functions for counting total movies, determining last movie year, and ranking by production year.
4. STRING_AGG function to collect unique keywords associated with the movies, showcasing string manipulation.
5. COALESCE to handle NULL movie titles gracefully, giving a default message if no recent movies were found for an actor.
6. Usage of case expressions for categorizing movies based on their release years.
7. Filtering and ordering with NULL logic in the final output to enhance the usability of the results.
8. Ordering to prioritize recent activities while ensuring that actors with no movies also show up rather unsorted.
