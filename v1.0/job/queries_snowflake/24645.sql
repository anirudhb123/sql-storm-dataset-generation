
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
company_movie_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        LISTAGG(DISTINCT cn.name, '; ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
actor_info AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ak.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 3
),
popular_directors AS (
    SELECT 
        ak.name AS director_name,
        COUNT(DISTINCT m.id) AS directed_movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title m ON m.id = ci.movie_id AND ci.role_id = (SELECT id FROM role_type WHERE role = 'director')
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT m.id) >= 5
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(cs.company_count, 0) AS company_count,
    cs.company_names,
    COALESCE(ai.actor_name, 'N/A') AS actor_name,
    COALESCE(ai.movies_count, 0) AS actor_movie_count,
    COALESCE(pd.director_name, 'N/A') AS director_name,
    COALESCE(pd.directed_movies, 0) AS director_movies_count
FROM 
    ranked_movies r
LEFT JOIN 
    company_movie_summary cs ON r.movie_id = cs.movie_id
LEFT JOIN 
    actor_info ai ON ai.movies_count > 3 AND r.movie_id = ai.person_id
LEFT JOIN 
    popular_directors pd ON pd.director_name = ai.actor_name
WHERE 
    r.actor_rank = 1
ORDER BY 
    r.production_year DESC,
    ai.movies_count DESC
LIMIT 20;
