WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rnk
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        RankedMovies t ON ci.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND a.name <> ''
    GROUP BY 
        c.person_id, a.name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        movies,
        RANK() OVER (ORDER BY movie_count DESC) as actor_rank
    FROM 
        ActorDetails
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    ta.movies,
    t.title AS top_movie,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = MAX(rm.movie_id) AND mi.info_type_id = 1) AS award_count
FROM 
    TopActors ta
LEFT JOIN 
    RankedMovies rm ON ta.movies LIKE '%' || rm.title || '%'
LEFT JOIN 
    aka_title t ON rm.movie_id = t.id AND ta.movie_count > 0
WHERE 
    ta.actor_rank <= 10
ORDER BY 
    ta.movie_count DESC, 
    NULLIF(rm.production_year IS NOT NULL, false) DESC,
    t.title;
