WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
        AND ak.name IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        MAX(production_year) AS latest_movie_year
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
)
SELECT 
    rs.movie_title,
    rs.production_year,
    rs.actor_name,
    ak.keywords,
    ast.total_movies,
    ast.latest_movie_year
FROM 
    RankedMovies rs
JOIN 
    MovieKeywords ak ON rs.movie_id = ak.movie_id
JOIN 
    ActorStats ast ON rs.actor_name = ast.actor_name
WHERE 
    rs.actor_rank <= 3  -- Get top 3 actors per movie
ORDER BY 
    rs.production_year DESC, 
    rs.movie_title,
    rs.actor_name;

This query retrieves a ranked list of actors associated with movies produced from the year 2000 onwards, along with their associated keywords, the total number of movies they have appeared in, and the year of their latest movie. It filters to show only the top three actors per movie and orders the results by production year and movie title.
