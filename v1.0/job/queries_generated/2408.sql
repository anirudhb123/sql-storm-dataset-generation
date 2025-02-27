WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieGenres AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
), ActorDetails AS (
    SELECT 
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_worked_in,
        MAX(ci.nr_order) AS highest_role_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
) 
SELECT 
    R.title,
    R.production_year,
    R.actor_count,
    G.genres,
    A.name AS actor_name,
    A.movies_worked_in,
    COALESCE(A.highest_role_order, 0) AS highest_role_order
FROM 
    RankedMovies R
LEFT JOIN 
    MovieGenres G ON R.id = G.movie_id
LEFT JOIN 
    ActorDetails A ON A.movies_worked_in > 10
WHERE 
    R.rank <= 3
    AND (R.actor_count IS NULL OR R.actor_count > 5)
ORDER BY 
    R.production_year DESC, 
    R.actor_count DESC;
