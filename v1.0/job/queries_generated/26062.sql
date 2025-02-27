WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year, 
        COUNT(DISTINCT c.movie_id) AS total_movies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL 
    GROUP BY 
        a.name, t.title, t.production_year
), 
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        k.keyword, 
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id, k.keyword
),
KeywordStats AS (
    SELECT 
        movie_id, 
        STRING_AGG(keyword, ', ') AS keywords_list, 
        SUM(keyword_count) AS total_keywords
    FROM 
        MovieKeywords
    GROUP BY 
        movie_id
)
SELECT 
    am.actor_name, 
    am.movie_title, 
    am.production_year, 
    k.keywords_list, 
    k.total_keywords, 
    am.total_movies
FROM 
    ActorMovies am
LEFT JOIN 
    KeywordStats k ON am.movie_title = k.keywords_list
ORDER BY 
    am.actor_name, am.production_year DESC;

This query goes through several Common Table Expressions (CTEs) to gather comprehensive data about actors, their movies, and associated keywords for benchmarking string processing:

1. **ActorMovies** CTE retrieves a list of actors, the titles of the movies they've acted in, their production years, and the count of distinct movies associated with each actor.

2. **MovieKeywords** CTE fetches keyword information associated with each movie and counts them.

3. **KeywordStats** CTE aggregates keywords by movie, listing them as a comma-separated string, while also counting the total number of keywords.

Finally, the main SELECT statement joins these CTEs on the actor's movie titles to produce a full output, organized by actor name and production year, providing an elaborate overview of string data manipulation and aggregation tasks.
