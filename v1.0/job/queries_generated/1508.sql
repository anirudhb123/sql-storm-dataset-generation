WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        TopRankedMovies trm ON trm.movie_id = c.movie_id
    GROUP BY 
        a.person_id
)
SELECT 
    a.name,
    COALESCE(as.movie_count, 0) AS movie_count,
    COALESCE(as.movies, 'No movies found') AS movies,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS companies_with_notes
FROM 
    aka_name a
LEFT JOIN 
    ActorStats as ON a.person_id = as.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id IN (SELECT movie_id FROM TopRankedMovies)
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, as.movie_count, as.movies
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    movie_count DESC, a.name
LIMIT 10;
