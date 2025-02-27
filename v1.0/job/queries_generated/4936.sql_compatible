
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        a.id
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
actor_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keyword,
    ac.actor_count,
    ci.companies
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_counts ac ON rm.id = ac.movie_id
LEFT JOIN 
    company_info ci ON rm.id = ci.movie_id
WHERE 
    rm.year_rank <= 5
    AND (ac.actor_count IS NULL OR ac.actor_count > 3)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
