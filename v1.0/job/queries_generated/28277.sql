WITH NameStatistics AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles,
        COUNT(DISTINCT w.keyword) AS unique_keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword w ON mk.keyword_id = w.id
    GROUP BY 
        a.name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        titles,
        unique_keywords,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        NameStatistics
)
SELECT 
    actor_name,
    movie_count,
    titles,
    unique_keywords
FROM 
    TopActors
WHERE 
    rank <= 10
ORDER BY 
    movie_count DESC;

This SQL query retrieves the top 10 actors based on the number of movies they have acted in, along with the titles of those movies and the count of unique keywords associated with them. The query utilizes CTEs (Common Table Expressions) to first compute statistics related to actors and their movies, and then selects the top actors based on the computed statistics.
