WITH MovieYearCount AS (
    SELECT 
        a.production_year, 
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    GROUP BY 
        a.production_year
), 
TopMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_info mi ON a.id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
        AND mi.info IS NOT NULL
), 
CastRoles AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count, 
        MAX(CASE WHEN ci.nr_order = 1 THEN r.role END) AS main_role
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    m.production_year,
    COUNT(DISTINCT t.title) AS title_count,
    COALESCE(MAX(cr.actor_count), 0) AS max_actors,
    COALESCE(SUM(mb.movie_count), 0) AS total_movies
FROM 
    MovieYearCount mb
JOIN 
    TopMovies t ON mb.production_year = t.production_year AND t.rank <= 5
LEFT JOIN 
    CastRoles cr ON t.movie_id = cr.movie_id
WHERE 
    mb.movie_count > 10
GROUP BY 
    m.production_year
HAVING 
    AVG(cr.actor_count) IS NOT NULL 
ORDER BY 
    m.production_year DESC;
