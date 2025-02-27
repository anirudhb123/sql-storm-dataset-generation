WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
company_details AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title, 
    rm.production_year,
    rm.actor_count,
    cd.company_name,
    cd.company_type
FROM 
    ranked_movies rm
LEFT JOIN 
    company_details cd ON rm.title = cd.movie_id 
WHERE 
    rm.rank <= 5
    AND rm.actor_count IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC, 
    cd.company_name ASC;
