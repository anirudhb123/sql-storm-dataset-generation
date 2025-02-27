WITH ActorRanking AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT ti.title, ', ') AS movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title ti ON ci.movie_id = ti.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
),
PopularMovies AS (
    SELECT 
        title.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title
    JOIN 
        movie_keyword mk ON title.id = mk.movie_id
    GROUP BY 
        title.title
    HAVING 
        COUNT(mk.keyword_id) > 5
),
ActorMovieOverview AS (
    SELECT 
        ar.actor_name,
        ar.movie_count,
        pm.title AS popular_movie,
        (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = pm.id) AS company_count
    FROM 
        ActorRanking ar
    JOIN 
        PopularMovies pm ON ar.movies LIKE '%' || pm.title || '%'
)
SELECT 
    amo.actor_name,
    amo.movie_count,
    amo.popular_movie,
    amo.company_count
FROM 
    ActorMovieOverview amo
ORDER BY 
    amo.movie_count DESC, 
    amo.popular_movie;

This query performs the following steps:

1. **ActorRanking**: Computes the number of movies and a list of distinct titles for each actor from the `aka_name`, `cast_info`, and `aka_title` tables.
   
2. **PopularMovies**: Identifies movies that have more than 5 associated keywords.

3. **ActorMovieOverview**: Combines the rankings from the first step with the popular movies, along with counting how many companies are associated with each popular movie.

4. The final selection retrieves the actor name, their movie count, popular movie titles, and associated company counts, ordered by the number of movies an actor has been in, in descending order.
