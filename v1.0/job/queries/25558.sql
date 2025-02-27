WITH actor_movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND 
        LENGTH(a.name) > 0
    GROUP BY 
        a.id, a.name
),
movies_with_keywords AS (
    SELECT 
        t.id AS movie_id,
        t.title AS title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title
),
actor_movie_stats AS (
    SELECT 
        am.actor_id,
        am.actor_name,
        am.total_movies,
        mwk.title,
        mwk.keywords
    FROM 
        actor_movies am
    JOIN 
        movies_with_keywords mwk ON am.movie_titles LIKE '%' || mwk.title || '%'
    ORDER BY 
        am.total_movies DESC, am.actor_name
)
SELECT 
    actor_id,
    actor_name,
    total_movies,
    title,
    keywords
FROM 
    actor_movie_stats
WHERE 
    total_movies > 5
LIMIT 50;
