WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'documentary'))
),
actor_movie_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        ranked_movies m ON c.movie_id = m.movie_id
    GROUP BY 
        c.person_id
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
actor_info AS (
    SELECT 
        a.name,
        pc.info AS role,
        am.movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        actor_movie_counts am ON a.person_id = am.person_id
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        role_type pc ON c.role_id = pc.id
)
SELECT 
    ai.name,
    COALESCE(ai.role, 'Unknown') AS role,
    COALESCE(mw.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT mw.movie_id) AS movies_with_keywords,
    AVG(am.movie_count) AS avg_movies_per_actor
FROM 
    actor_info ai
LEFT JOIN 
    movies_with_keywords mw ON ai.movie_count = mw.movie_id
LEFT JOIN 
    actor_movie_counts am ON ai.movie_count = am.movie_count
WHERE 
    ai.movie_count > 0
GROUP BY 
    ai.name, ai.role, mw.keywords
HAVING 
    COUNT(DISTINCT mw.movie_id) > 0
ORDER BY 
    avg_movies_per_actor DESC, ai.name;
