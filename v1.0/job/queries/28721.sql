WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        CASE 
            WHEN t.production_year IS NOT NULL THEN 'Produced' 
            ELSE 'Unknown' 
        END AS production_status
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
), 

PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actors,
        keywords,
        production_status,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    pm.movie_id,
    pm.title,
    pm.production_year,
    pm.cast_count,
    pm.actors,
    pm.keywords,
    pm.production_status
FROM 
    PopularMovies pm
WHERE 
    pm.rank <= 10
ORDER BY 
    pm.cast_count DESC;
