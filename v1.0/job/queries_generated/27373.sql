WITH movie_characteristics AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        t.id AS title_id, 
        t.title AS movie_title, 
        t.production_year, 
        t.kind_id, 
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        a.id, a.name, t.id, t.title, t.production_year, t.kind_id
),
actor_performance AS (
    SELECT 
        mc.actor_id,
        mc.actor_name,
        mc.movie_title,
        mc.production_year,
        mc.keyword_count,
        COALESCE(mt.kind, 'Unknown') AS movie_type
    FROM 
        movie_characteristics mc
    LEFT JOIN 
        kind_type mt ON mc.kind_id = mt.id
)
SELECT 
    ap.actor_name,
    COUNT(DISTINCT ap.movie_title) AS movies_featured,
    SUM(ap.keyword_count) AS total_keywords,
    STRING_AGG(DISTINCT ap.movie_title, '; ') AS featured_movies
FROM 
    actor_performance ap
GROUP BY 
    ap.actor_name
HAVING 
    COUNT(DISTINCT ap.movie_title) > 5
ORDER BY 
    total_keywords DESC, movies_featured DESC;
