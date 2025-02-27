WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        cte.level + 1
    FROM 
        MovieCTE cte
    JOIN 
        movie_link ml ON cte.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        cte.level < 3  -- limit the recursion depth
),
RankedMovies AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY r.role) AS role_order
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        rm.actor_count
    FROM 
        MovieCTE m
    LEFT JOIN 
        RankedMovies rm ON m.movie_id = rm.movie_id
    WHERE 
        rm.actor_count > 1 OR rm.actor_count IS NULL
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(f.actor_count, 0) AS total_actors,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = f.movie_id AND info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_info_count
FROM 
    FilteredMovies f
LEFT JOIN 
    aka_name an ON an.person_id = (SELECT c.person_id FROM cast_info c WHERE c.movie_id = f.movie_id ORDER BY c.nr_order LIMIT 1)
ORDER BY 
    f.production_year DESC, f.total_actors DESC;

This complex SQL query includes several constructs:

1. A recursive Common Table Expression (CTE) called `MovieCTE` which navigates through linked movies produced after the year 2000, with a limited recursion depth.
2. A CTE called `RankedMovies` that counts the number of actors per movie and ranks their roles.
3. A filtered selection of movies (`FilteredMovies`) ensuring that only movies with more than one actor (or none) are included.
4. The main SELECT statement retrieves titles, production years, the count of actors (handling NULL values), and counts of additional movie information related to box office details.
5. LEFT JOINs are utilized to fetch additional details from related tables, demonstrating flexibility in dealing with missing data (NULL logic).
