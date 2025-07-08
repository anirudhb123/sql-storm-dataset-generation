WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        kv.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kv ON mk.keyword_id = kv.id
    WHERE 
        t.production_year IS NOT NULL
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.kind_id,
        rm.movie_keyword
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank_by_title <= 5  
),
actor_movies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    WHERE 
        ci.note IS NULL  
    GROUP BY 
        ci.movie_id
),
final_results AS (
    SELECT 
        tm.movie_id,
        tm.movie_title,
        tm.production_year,
        tm.movie_keyword,
        am.actor_count
    FROM 
        top_movies tm
    LEFT JOIN 
        actor_movies am ON tm.movie_id = am.movie_id
)
SELECT 
    fr.movie_title,
    fr.production_year,
    fr.movie_keyword,
    COALESCE(fr.actor_count, 0) AS actor_count
FROM 
    final_results fr
ORDER BY 
    fr.production_year DESC, fr.movie_title ASC;