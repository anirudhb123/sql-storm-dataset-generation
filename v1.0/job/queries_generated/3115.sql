WITH actor_movies AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        cast_info c
    JOIN 
        complete_cast ci ON c.movie_id = ci.movie_id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        c.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
top_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        am.movie_count,
        COALESCE(mk.keyword_count, 0) AS keyword_count
    FROM 
        aka_name a
    LEFT JOIN 
        actor_movies am ON a.person_id = am.person_id
    LEFT JOIN 
        movie_keywords mk ON am.movies LIKE '%' || mk.movie_id || '%'
    WHERE 
        a.name IS NOT NULL
),
ranked_actors AS (
    SELECT 
        actor_id,
        name,
        movie_count,
        keyword_count,
        RANK() OVER (ORDER BY movie_count DESC, keyword_count DESC) AS actor_rank
    FROM 
        top_actors
)
SELECT 
    r.actor_id,
    r.name,
    r.movie_count,
    r.keyword_count,
    CASE 
        WHEN r.actor_rank <= 10 THEN 'Top 10 Actor'
        ELSE 'Other Actor'
    END AS category
FROM 
    ranked_actors r
WHERE 
    r.keyword_count > 5
ORDER BY 
    r.actor_rank;
