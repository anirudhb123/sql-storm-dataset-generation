WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS num_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_list
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(c.person_id) > 5
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.num_actors,
    rm.actors_list,
    km.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordMovies km ON rm.movie_id = km.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.num_actors DESC;