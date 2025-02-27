
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
),

company_movie_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    cmi.companies,
    cmi.company_types
FROM 
    ranked_movies rm
LEFT JOIN 
    company_movie_info cmi ON rm.production_year = cmi.movie_id
WHERE 
    rm.actor_count > 5 AND 
    (cmi.companies IS NOT NULL OR cmi.company_types IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC
LIMIT 50;
