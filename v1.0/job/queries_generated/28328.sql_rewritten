WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_info AS c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name AS a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
), FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.actor_names
    FROM 
        RankedMovies AS rm
    WHERE 
        rm.actor_count > 3  
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.actor_names,
    kc.keyword AS movie_keyword
FROM 
    FilteredMovies AS fm
LEFT JOIN 
    movie_keyword AS mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS kc ON mk.keyword_id = kc.id
ORDER BY 
    fm.production_year DESC, 
    fm.actor_count DESC;