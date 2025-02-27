WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
top_movies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        ranked_titles rt
    WHERE 
        rt.rank <= 10
),
actor_movies AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        tt.title AS movie_title,
        tt.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        top_movies tt ON ci.movie_id = tt.title_id
)
SELECT 
    am.actor_name,
    COUNT(DISTINCT am.movie_id) AS movies_count,
    STRING_AGG(DISTINCT am.movie_title, ', ') AS movie_titles,
    STRING_AGG(DISTINCT am.production_year::text, ', ') AS production_years
FROM 
    actor_movies am
GROUP BY 
    am.actor_name
ORDER BY 
    movies_count DESC
LIMIT 5;
