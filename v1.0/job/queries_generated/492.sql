WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_within_year
    FROM 
        title t
),
ActorMovies AS (
    SELECT 
        k.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(m.production_year) AS average_year
    FROM 
        aka_name k
    JOIN 
        cast_info ci ON k.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.movie_id
    GROUP BY 
        k.name
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(a.movie_count, 0) AS actor_movies,
        COALESCE(a.average_year, 0) AS average_actor_year
    FROM 
        title m
    LEFT JOIN 
        ActorMovies a ON m.id = a.movie_id
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    f.actor_movies,
    f.average_actor_year
FROM 
    RankedTitles r
LEFT JOIN 
    FilteredMovies f ON r.title_id = f.movie_id
WHERE 
    (f.actor_movies > 0 OR f.actor_movies IS NULL)
    AND r.rank_within_year <= 5
ORDER BY 
    r.production_year ASC, r.title ASC;
