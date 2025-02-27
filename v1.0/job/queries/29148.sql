WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        actor_names
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 AND cast_count > 5
)
SELECT 
    f.movie_title,
    f.production_year,
    f.cast_count,
    f.actor_names,
    m.info AS genre_info,
    k.keyword AS keywords
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_info m ON f.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
LEFT JOIN 
    movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
