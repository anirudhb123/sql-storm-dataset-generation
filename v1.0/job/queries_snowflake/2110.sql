
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        COUNT(ci.id) AS appearances
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, a.name, rt.role
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mi.info, '; ') AS movie_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(mv.movie_details, 'No details available') AS movie_details,
    COALESCE(mc.actor_name, 'No cast information') AS actor_name,
    COUNT(DISTINCT mc.actor_name) AS total_actors,
    CASE 
        WHEN m.rank_title BETWEEN 1 AND 5 THEN 'Top 5 of the Year'
        ELSE 'Below Top 5'
    END AS performance_category
FROM 
    RankedMovies m
LEFT JOIN 
    MovieInfo mv ON m.movie_id = mv.movie_id
LEFT JOIN 
    MovieCast mc ON m.movie_id = mc.movie_id
WHERE 
    m.production_year = (SELECT MAX(production_year) FROM RankedMovies)
GROUP BY 
    m.movie_id, m.title, m.production_year, mv.movie_details, mc.actor_name, m.rank_title
ORDER BY 
    m.title ASC;
