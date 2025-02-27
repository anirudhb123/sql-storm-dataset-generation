WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
recent_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        string_agg(DISTINCT ak.name, ', ') AS all_actors,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mw ON t.id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.rn,
    COALESCE(rm_all.all_actors, 'No actors available') AS all_actors,
    COALESCE(rm_all.keyword_count, 0) AS keyword_count
FROM 
    ranked_movies rm
LEFT JOIN 
    recent_movies rm_all ON rm.title = rm_all.title AND rm.production_year = rm_all.production_year
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
