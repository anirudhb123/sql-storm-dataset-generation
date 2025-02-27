WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT 
        r.title,
        r.production_year,
        r.actor_count
    FROM 
        ranked_movies r
    WHERE 
        r.actor_count > (SELECT AVG(actor_count) FROM ranked_movies)
),
company_movie_counts AS (
    SELECT 
        m.movie_id,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
final_results AS (
    SELECT 
        f.title,
        f.production_year,
        f.actor_count,
        COALESCE(c.company_count, 0) AS company_count
    FROM 
        filtered_movies f
    LEFT JOIN 
        company_movie_counts c ON f.title = (SELECT title FROM aka_title WHERE id = f.title)
)
SELECT 
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.company_count,
    CASE 
        WHEN fr.company_count = 0 THEN 'No Companies'
        ELSE 'Companies Present'
    END AS companies_status
FROM 
    final_results fr
WHERE 
    fr.actor_count BETWEEN 5 AND 20
ORDER BY 
    fr.production_year DESC, fr.actor_count DESC;
