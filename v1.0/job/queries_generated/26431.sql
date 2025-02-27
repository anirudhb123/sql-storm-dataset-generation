WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title AS t
    INNER JOIN 
        cast_info AS c ON t.id = c.movie_id
    INNER JOIN 
        aka_name AS a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    r.movie_title, 
    r.production_year, 
    r.cast_count, 
    r.actor_names, 
    mk.keywords
FROM 
    RankedMovies AS r
LEFT JOIN 
    MovieKeywords AS mk ON r.movie_id = mk.movie_id
ORDER BY 
    r.production_year DESC, 
    r.cast_count DESC
LIMIT 10;
