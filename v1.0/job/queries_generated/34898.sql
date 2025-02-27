WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id AS actor_id,
        p.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS movies_count,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    LEFT JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    GROUP BY 
        c.person_id, p.name
    UNION ALL
    SELECT 
        ch.actor_id,
        ch.actor_name,
        ch.movies_count + COUNT(DISTINCT c.movie_id),
        level + 1
    FROM 
        actor_hierarchy ch
    JOIN 
        cast_info c ON ch.actor_id = c.person_id
    GROUP BY 
        ch.actor_id, ch.actor_name, ch.movies_count, level
),
movie_info_extended AS (
    SELECT 
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        AVG(p.rating) AS average_rating
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        (SELECT movie_id, AVG(rating) AS rating FROM movie_rating GROUP BY movie_id) p ON m.id = p.movie_id
    GROUP BY 
        m.title, m.production_year
),
actor_movies AS (
    SELECT 
        a.actor_name,
        COUNT(DISTINCT ca.movie_id) AS total_movies
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ca ON a.person_id = ca.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.actor_name
)
SELECT 
    a.actor_name,
    a.total_movies,
    COALESCE(m.keywords, 'No keywords') AS keywords,
    COALESCE(m.average_rating, 'N/A') AS avg_rating,
    ah.level AS hierarchy_level
FROM 
    actor_movies a
LEFT JOIN 
    movie_info_extended m ON a.total_movies > 0
LEFT JOIN 
    actor_hierarchy ah ON a.actor_name = ah.actor_name
WHERE 
    a.total_movies > 5
ORDER BY 
    a.total_movies DESC,
    ah.level ASC;

This SQL query performs a number of interesting functions:

1. **Recursive CTE `actor_hierarchy`**: This builds a hierarchy of actors based on the movies they've participated in.

2. **CTE `movie_info_extended`**: This aggregates movie information including production years and associated keywords along with average ratings.

3. **CTE `actor_movies`**: Counts the number of movies each actor has appeared in.

4. **Final Select Statement**: Retrieves actor names with a count of their movies, keywords associated with those movies, average ratings, and hierarchy levels while applying filters and ordering for meaningful output.

5. **Use of `COALESCE()`**: This function handles NULL values gracefully.

6. **Use of String Aggregation**: The query demonstrates string functions by also aggregating keywords associated with movies.

This query could serve as a performance benchmark by testing the efficiency of handling complex joins, subqueries, CTEs, and window functions within a relational database.
