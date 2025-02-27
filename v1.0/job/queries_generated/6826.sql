WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(a.name, ', ') AS actor_names
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
), FilteredMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        total_cast,
        actor_names
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 AND total_cast > 5
)
SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.total_cast,
    f.actor_names,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    f.movie_id, f.movie_title, f.production_year, f.total_cast, f.actor_names
ORDER BY 
    f.production_year DESC, f.total_cast DESC;
