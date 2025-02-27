WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id, a.title, a.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5  -- Only movies with more than 5 unique actors
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names,
        ARRAY(
            SELECT 
                k.keyword 
            FROM 
                movie_keyword mk
            JOIN 
                keyword k ON mk.keyword_id = k.id
            WHERE 
                mk.movie_id = rm.movie_id
        ) AS keywords
    FROM 
        RankedMovies rm
)

SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    f.actor_names,
    f.keywords,
    COALESCE(MAX(m.info), 'No Info') AS additional_info
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_info m ON f.movie_id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
GROUP BY 
    f.movie_id, f.title, f.production_year, f.cast_count, f.actor_names
ORDER BY 
    f.production_year DESC, f.cast_count DESC
LIMIT 10;
