WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), company_movies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
), movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        cm.company_count,
        cm.companies
    FROM 
        ranked_movies rm
    LEFT JOIN 
        company_movies cm ON rm.movie_id = cm.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.cast_count, 0) AS cast_count,
    COALESCE(md.company_count, 0) AS company_count,
    CASE 
        WHEN md.company_count IS NOT NULL THEN 'Has Companies'
        ELSE 'No Companies'
    END AS company_status,
    (SELECT AVG(ci.nr_order) 
     FROM cast_info ci 
     WHERE ci.movie_id = md.movie_id) AS avg_order
FROM 
    movie_details md
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 10;
