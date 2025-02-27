WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
), 
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), 
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    t.title, 
    t.production_year, 
    mr.actor_name,
    mr.role_name,
    COALESCE(ci.company_names, '{}'::text[]) AS companies,
    COALESCE(ks.keyword_count, 0) AS keyword_total,
    COUNT(DISTINCT mr.actor_name) OVER (PARTITION BY t.id) AS actor_count
FROM 
    title t
LEFT JOIN 
    MovieRoles mr ON t.id = mr.movie_id
LEFT JOIN 
    CompanyInfo ci ON t.id = ci.movie_id
LEFT JOIN 
    KeywordStats ks ON t.id = ks.movie_id
WHERE 
    (t.production_year > 2000 OR t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie'))
    AND (mr.role_name IS NOT NULL OR ci.total_companies > 5)
ORDER BY 
    t.production_year DESC, 
    actor_count DESC, 
    mr.role_order;
