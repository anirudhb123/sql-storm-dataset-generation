WITH ranked_titles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT 
        ai.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    GROUP BY 
        ai.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
company_movie_stats AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS total_movies,
        MIN(t.production_year) AS first_movie_year,
        MAX(t.production_year) AS last_movie_year
    FROM 
        movie_companies mc
    JOIN 
        aka_title t ON mc.movie_id = t.id
    GROUP BY 
        mc.company_id
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 10
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies_with_roles,
    r.production_year AS latest_year,
    c.company_id AS production_company,
    cs.total_movies AS company_total_movies,
    COALESCE(cs.first_movie_year, 'No movies recorded') AS first_movie_record_year,
    COALESCE(cs.last_movie_year, 'No movies recorded') AS last_movie_record_year
FROM 
    actor_movie_counts amc
JOIN 
    aka_name a ON amc.person_id = a.person_id
JOIN 
    cast_info c ON c.person_id = a.person_id
JOIN 
    ranked_titles r ON r.title = (SELECT title FROM aka_title WHERE id = c.movie_id)
LEFT JOIN 
    company_movie_stats cs ON cs.company_id = (
        SELECT mc.company_id 
        FROM movie_companies mc 
        WHERE mc.movie_id = c.movie_id 
        LIMIT 1
    )
WHERE 
    r.year_rank = 1
GROUP BY 
    a.name, r.production_year, c.company_id, cs.total_movies
ORDER BY 
    total_movies_with_roles DESC, latest_year DESC;
