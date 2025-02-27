WITH RECURSIVE MovieRecursive AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS depth,
        CAST(t.title AS VARCHAR(255)) AS full_path
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.linked_movie_id,
        a.title,
        a.production_year,
        mr.depth + 1,
        CAST(mr.full_path || ' -> ' || a.title AS VARCHAR(255))
    FROM 
        MovieRecursive mr
    JOIN 
        movie_link m ON mr.movie_id = m.movie_id
    JOIN 
        aka_title a ON m.linked_movie_id = a.id
),

ActorMovies AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY a.id DESC) AS rn
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ak.person_id = ca.person_id
    JOIN 
        aka_title a ON a.id = ca.movie_id
),

FilteredActors AS (
    SELECT 
        person_id,
        actor_name,
        movie_id,
        COUNT(m.movie_id) AS movie_count
    FROM 
        ActorMovies ma
    JOIN 
        MovieRecursive m ON ma.movie_id = m.movie_id
    WHERE 
        m.depth <= 3
    GROUP BY 
        person_id, actor_name, movie_id
    HAVING 
        COUNT(m.movie_id) >= ALL(SELECT COUNT(*) FROM ActorMovies GROUP BY person_id)
)

SELECT 
    f.actor_name,
    f.movie_id,
    f.movie_count,
    COALESCE(m.title, 'No Title') AS movie_title,
    COALESCE(m.production_year, 0) AS movie_year,
    (SELECT COUNT(*)
     FROM link_type lt
     JOIN movie_link ml ON lt.id = ml.link_type_id
     WHERE ml.movie_id = f.movie_id) AS link_count,
    CASE
        WHEN f.movie_count IS NULL THEN 'Unknown'
        WHEN f.movie_count = 1 THEN 'Solo Actor'
        ELSE 'Group Actor'
    END AS actor_type
FROM 
    FilteredActors f
LEFT JOIN 
    aka_title m ON f.movie_id = m.id
WHERE 
    f.actor_name IS NOT NULL
ORDER BY 
    f.movie_count DESC, m.production_year DESC
LIMIT 10;

This query does the following:
1. Creates a recursive Common Table Expression (CTE) called `MovieRecursive` to fetch movies and their linked counterparts, tracking their depth in the hierarchy.
2. Joins the `cast_info` table with `aka_name` and `aka_title` to gather information about actors and the movies they've acted in, assigning a row number for each actor's movies.
3. In `FilteredActors`, it filters actors who have acted in the top movies (as determined by a count based on the depth from the `MovieRecursive` CTE), allowing at most three levels of linked movies.
4. The final select retrieves the actor's name, movie ID, count of movies, and joins with `aka_title` to get movie titles and production years.
5. It uses a subquery to calculate and display the count of links associated with each movie.
6. Finally, categorizes actors as "Solo Actor" or "Group Actor" based on their movie count, and limits the number of returned results to 10, sorting them by the number of movies. 

This query encapsulates a variety of SQL constructs, including recursive CTEs, window functions, subqueries, outer joins, and case expressions involving NULL logic.
