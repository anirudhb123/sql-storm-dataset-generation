WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
),
MoviesWithActors AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        ad.name AS actor_name,
        ad.movie_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        ActorDetails ad ON m.movie_id = ad.person_id
    WHERE 
        ad.movie_count IS NOT NULL
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.actor_name, 'No Actor Listed') AS actor_name,
    CASE
        WHEN m.movie_count IS NULL THEN 'N/A'
        ELSE m.movie_count::text
    END AS actor_movie_count
FROM 
    MoviesWithActors m
WHERE 
    m.year_rank <= 5
ORDER BY 
    m.production_year DESC, m.title;
