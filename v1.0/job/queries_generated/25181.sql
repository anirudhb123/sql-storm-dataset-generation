WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        m.id, m.title, m.production_year
),
PopularGenres AS (
    SELECT 
        k.keyword AS genre,
        COUNT(m.movie_id) AS movie_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        k.keyword
    ORDER BY 
        movie_count DESC
    LIMIT 5
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.cast_names,
    pg.genre
FROM 
    RankedMovies rm
JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
JOIN 
    PopularGenres pg ON mk.keyword_id = (SELECT id FROM keyword WHERE keyword = pg.genre)
WHERE 
    rm.cast_count > 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
