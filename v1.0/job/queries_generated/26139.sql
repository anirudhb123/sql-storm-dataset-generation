WITH RecursiveActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        m.title AS movie_title,
        m.production_year,
        RANK() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS rank_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.movie_id
    WHERE 
        a.name LIKE 'A%'  -- Selecting actors whose name starts with 'A'
),
FilteredMovies AS (
    SELECT 
        actor_id,
        actor_name,
        movie_id,
        movie_title,
        production_year
    FROM 
        RecursiveActorMovies
    WHERE 
        rank_year <= 3    -- Getting the latest 3 movies for each actor
),
MovieKeywords AS (
    SELECT 
        fm.actor_id,
        fm.actor_name,
        fm.movie_id,
        fm.movie_title,
        fm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies fm
    JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        fm.actor_id, fm.actor_name, fm.movie_id, fm.movie_title, fm.production_year
)
SELECT 
    fk.actor_id,
    fk.actor_name,
    fk.movie_title,
    fk.production_year,
    COALESCE(fk.keywords, 'No keywords available') AS keywords
FROM 
    MovieKeywords fk
ORDER BY 
    fk.actor_id, 
    fk.production_year DESC;
