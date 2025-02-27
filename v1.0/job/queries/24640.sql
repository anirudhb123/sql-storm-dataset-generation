
WITH RECURSIVE movie_roles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id, rt.role ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_type_id) AS company_types_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mci.companies, 'No companies') AS companies,
    COALESCE(mci.company_types_count, 0) AS company_types_count,
    CASE 
        WHEN mr.role IS NOT NULL THEN CONCAT(mr.actor_name, ' as ', mr.role)
        ELSE 'Unknown Actor'
    END AS leading_actor
FROM 
    title t 
LEFT JOIN 
    movie_keywords mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_company_info mci ON t.id = mci.movie_id
LEFT JOIN 
    (SELECT 
        movie_id, 
        actor_name, 
        role 
     FROM 
        movie_roles 
     WHERE 
        role_order = 1
    ) mr ON t.id = mr.movie_id
WHERE 
    t.production_year IS NOT NULL 
    AND (COALESCE(mci.company_types_count, 0) > 1 OR mk.keywords IS NOT NULL)
ORDER BY 
    t.production_year DESC,
    t.title ASC
LIMIT 100
OFFSET 20;
