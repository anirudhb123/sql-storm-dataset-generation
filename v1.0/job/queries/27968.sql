WITH ranked_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
top_actors AS (
    SELECT 
        actor_id, 
        actor_name, 
        movies_count,
        RANK() OVER (ORDER BY movies_count DESC) AS rank
    FROM 
        ranked_actors
    WHERE 
        movies_count > 5
), 
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title
),
top_movies AS (
    SELECT 
        movie_id,
        movie_title,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        movies_with_keywords
    WHERE 
        keyword_count > 3
)
SELECT 
    ta.actor_name,
    tm.movie_title,
    tm.keyword_count 
FROM 
    top_actors ta
JOIN 
    cast_info ci ON ta.actor_id = ci.person_id
JOIN 
    top_movies tm ON ci.movie_id = tm.movie_id
ORDER BY 
    ta.rank, tm.keyword_count DESC;
