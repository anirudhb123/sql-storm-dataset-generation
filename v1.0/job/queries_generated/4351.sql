WITH MovieDetails AS (
    SELECT 
        mv.id AS movie_id,
        mv.title,
        COALESCE(MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END), 'N/A') AS genre,
        COALESCE(MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END), 'Unknown') AS summary,
        mv.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title mv
    LEFT JOIN 
        movie_info mi ON mv.id = mi.movie_id
    LEFT JOIN 
        cast_info c ON mv.id = c.movie_id
    GROUP BY 
        mv.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        genre,
        summary,
        production_year,
        actor_count,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        MovieDetails
    WHERE 
        production_year >= 2000
)
SELECT 
    tm.title,
    tm.genre,
    tm.summary,
    tm.production_year,
    tm.actor_count,
    COALESCE(aka.name, 'Unknown') AS main_actor,
    (SELECT COUNT(DISTINCT keyword_id) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = tm.movie_id) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name aka ON ci.person_id = aka.person_id
WHERE 
    tm.rank <= 10
    AND (aka.name IS NOT NULL OR ci.note IS NULL)
ORDER BY 
    tm.actor_count DESC, 
    tm.production_year ASC;
