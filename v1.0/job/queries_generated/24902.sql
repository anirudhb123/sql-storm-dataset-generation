WITH RecursiveMovieRoles AS (
    SELECT 
        c.person_id, 
        a.name AS actor_name,
        t.title, 
        t.production_year,
        ct.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        aka_title t ON t.id = c.movie_id
    JOIN 
        comp_cast_type ct ON ct.id = c.person_role_id
    WHERE 
        c.nr_order IS NOT NULL
    AND 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.info AS movie_info,
        COUNT(DISTINCT r.actor_name) AS actor_count,
        MAX(r.role_order) AS max_role_order
    FROM 
        movie_info m
    JOIN 
        RecursiveMovieRoles r ON r.title = m.info
    WHERE 
        m.note IS NULL
    GROUP BY 
        m.movie_id, m.info
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_info, 
        actor_count,
        max_role_order,
        DENSE_RANK() OVER (ORDER BY actor_count DESC, max_role_order DESC) AS ranking
    FROM 
        FilteredMovies
    WHERE 
        actor_count > 1
)
SELECT 
    t.movie_info AS "Movie Title",
    t.actor_count AS "Number of Actors",
    t.max_role_order AS "Max Role Order",
    CASE 
        WHEN t.ranking <= 5 THEN 'Top 5 Movie'
        WHEN t.actor_count IS NULL THEN 'No Actors'
        ELSE 'Other'
    END AS "Movie Category"
FROM 
    TopMovies t
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.movie_id
WHERE 
    (t.actor_count IS NOT NULL AND t.ranking <= 10)
    OR (mk.keyword IS NOT NULL AND mk.keyword LIKE '%Action%')
ORDER BY 
    t.actor_count DESC, t.max_role_order DESC, t.movie_info;
