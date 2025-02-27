WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
TopMovies AS (
    SELECT
        m.title,
        m.production_year,
        mr.actor_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY mr.actor_count DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        MovieRoles mr ON m.id = mr.movie_id
    WHERE 
        m.production_year >= 2000
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(t.actor_count, 0) AS actor_count,
    CASE 
        WHEN t.actor_count IS NULL THEN 'No Cast Information'
        WHEN t.rank <= 5 THEN 'Top 5 Movie'
        ELSE 'Other'
    END AS movie_category
FROM 
    TopMovies t
WHERE 
    (t.actor_count IS NOT NULL OR t.rank IS NOT NULL)
ORDER BY 
    t.production_year ASC, t.actor_count DESC;

-- Find the top 5 movies by the number of unique roles in each production year from 2000 onwards, including movies with no cast information as well.
