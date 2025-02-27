WITH MovieRoles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
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
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    COALESCE(mr.role_order, 0) AS role_order,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    cs.company_count,
    cs.company_names,
    COUNT(DISTINCT a.id) AS alias_count
FROM 
    title t
LEFT JOIN 
    MovieRoles mr ON t.id = mr.movie_id
LEFT JOIN 
    CompanyStats cs ON t.id = cs.movie_id
LEFT JOIN 
    KeywordStats ks ON t.id = ks.movie_id
LEFT JOIN 
    aka_title a ON t.id = a.movie_id
WHERE 
    t.production_year >= 2000
    AND (cs.company_count > 2 OR ks.keyword_count > 5)
GROUP BY 
    t.id, t.title, t.production_year, mr.role_order, cs.company_count, cs.company_names
ORDER BY 
    t.production_year DESC, 
    keyword_count DESC, 
    alias_count DESC;
