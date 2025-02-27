WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS production_company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.title, t.production_year
),
actor_stats AS (
    SELECT 
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS null_role_percentage
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
),
company_summary AS (
    SELECT 
        c.name,
        COUNT(DISTINCT mc.movie_id) AS movies_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        aka_title t ON mc.movie_id = t.id
    GROUP BY 
        c.name
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.production_company_count,
    as.name AS actor_name,
    as.movie_count AS actor_movies,
    as.null_role_percentage AS actor_null_percentage,
    cs.name AS company_name,
    cs.movies_count AS company_movies,
    cs.movie_titles
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_stats as ON rm.rank = 1 AND as.movie_count > 5
LEFT JOIN 
    company_summary cs ON cs.movies_count >= 10
WHERE 
    rm.production_year > 2000
ORDER BY 
    rm.production_year DESC, rm.production_company_count DESC, as.movie_count DESC;
