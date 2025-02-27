WITH RecursiveCTE AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        1 AS depth
    FROM 
        cast_info c
    WHERE 
        c.nr_order = 1

    UNION ALL

    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        r.depth + 1
    FROM 
        cast_info c
    JOIN 
        RecursiveCTE r ON c.movie_id = r.movie_id
    WHERE 
        c.nr_order > r.depth
),
MovieGenres AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword AS genre,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS genre_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MoviesWithActors AS (
    SELECT 
        t.title,
        t.production_year,
        a.name,
        c.nr_order,
        RANK() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    g.genre,
    CASE 
        WHEN a.name IS NOT NULL THEN a.name 
        ELSE 'Unknown Actor' 
    END AS actor_name,
    COALESCE(SUM(CASE WHEN r.depth IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_cast_depth,
    COUNT(DISTINCT g.genre) AS genre_count,
    MAX(a.actor_rank) AS highest_actor_rank
FROM 
    MoviesWithActors a
LEFT JOIN 
    MovieGenres g ON a.title = g.title AND a.production_year = g.production_year
LEFT JOIN 
    RecursiveCTE r ON a.cast_id = r.cast_id
WHERE 
    g.genre_rank = 1
GROUP BY 
    m.title, m.production_year, g.genre, a.name
HAVING 
    COUNT(DISTINCT a.person_id) > 2 AND 
    MAX(r.depth) > 1
ORDER BY 
    m.production_year DESC, 
    genre_count DESC;

This query performs a complex operation involving recursive common table expressions, window functions, outer joins, and aggregates. It retrieves movie titles and associated genres, the names of actors, a count of distinct genres per movie, and the total depth of the cast hierarchy. The use of COALESCE, CASE, and HAVING clauses adds layers of conditional logic to filter results based on specific criteria.
