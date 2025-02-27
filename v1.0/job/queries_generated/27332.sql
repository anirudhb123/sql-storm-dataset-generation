WITH Recursive_Actor_Movie AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS recent_movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
),
Actor_Movie_Summary AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(movie_id) AS total_movies,
        MAX(production_year) AS last_movie_year,
        STRING_AGG(title, ', ') AS movies
    FROM 
        Recursive_Actor_Movie
    WHERE 
        recent_movie_rank <= 5
    GROUP BY 
        actor_id, actor_name
),
Movie_Keyword_Summary AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title
),
Actor_Keyword_Insights AS (
    SELECT 
        am.actor_id,
        am.actor_name,
        am.total_movies,
        am.last_movie_year,
        mk.title,
        mk.keyword_count
    FROM 
        Actor_Movie_Summary am
    LEFT JOIN 
        Movie_Keyword_Summary mk ON mk.title ILIKE '%' || am.actor_name || '%'
)
SELECT 
    ak.actor_id,
    ak.actor_name,
    ak.total_movies,
    ak.last_movie_year,
    ak.title,
    ak.keyword_count
FROM 
    Actor_Keyword_Insights ak
WHERE 
    ak.keyword_count > 2
ORDER BY 
    ak.total_movies DESC, ak.last_movie_year DESC;

This SQL query performs the following tasks:

1. **Recursive_Actor_Movie:** It retrieves actor details alongside their recent movies, assigning a rank based on the production year.
2. **Actor_Movie_Summary:** It summarizes how many movies each actor has and lists the most recent movies they've participated in.
3. **Movie_Keyword_Summary:** It counts the keywords associated with each movie.
4. **Actor_Keyword_Insights:** It combines the previous summaries to create a detailed view of actors who appear in movies that include their names in the title and have more than a certain amount of related keywords.
5. Finally, it filters and orders the results based on total movies and the release date of the last movie.
