
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

MovieGenres AS (
    SELECT 
        title.id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY k.keyword) AS genre_rank
    FROM 
        title 
    INNER JOIN 
        movie_keyword mk ON title.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    COALESCE(mg.keyword, 'Unknown') AS genre,
    CASE 
        WHEN rm.actor_count > 5 THEN 'Featured'
        WHEN rm.actor_count IS NULL THEN 'No Actors'
        ELSE 'Standard'
    END AS movie_status
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.id AND mg.genre_rank = 1
WHERE 
    rm.actor_rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC,
    rm.title ASC;
