
WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(DISTINCT ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
company_movies AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cr.role_count, 0) AS total_roles,
    COALESCE(cm.company_names, '{}') AS production_companies,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN rm.year_rank > 5 THEN 'Older Film'
        ELSE 'Recent Film'
    END AS film_age_category
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_roles cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    company_movies cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year > 2000
ORDER BY 
    rm.production_year DESC, rm.title;
