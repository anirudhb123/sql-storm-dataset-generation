WITH ranked_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
top_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.actor_id) AS actor_count
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        actor_count DESC
    LIMIT 10
),
keyword_stats AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
)
SELECT 
    t.movie_title,
    t.production_year,
    ra.actor_name,
    ra.movie_count,
    ks.keyword,
    ks.keyword_count
FROM 
    top_movies t
JOIN 
    ranked_actors ra ON t.movie_id = ra.actor_id
JOIN 
    keyword_stats ks ON t.movie_id = ks.movie_id
WHERE 
    ra.actor_rank <= 5
ORDER BY 
    t.production_year DESC, 
    ra.movie_count DESC, 
    ks.keyword_count DESC;
