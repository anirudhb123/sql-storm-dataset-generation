WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000  -- filter for modern movies
    GROUP BY 
        m.id, m.title, m.production_year
),
RankedActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title m ON c.movie_id = m.id
    GROUP BY 
        a.person_id, a.name
),
HighProfileActors AS (
    SELECT 
        ra.person_id,
        ra.name,
        ra.movie_count
    FROM 
        RankedActors ra
    WHERE 
        ra.movie_count > 10  -- filter for actors that have been in more than 10 movies
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    rm.actors,
    rm.keywords,
    hpa.name AS featured_actor
FROM 
    RankedMovies rm
LEFT JOIN 
    HighProfileActors hpa ON rm.actors LIKE '%' || hpa.name || '%'
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
