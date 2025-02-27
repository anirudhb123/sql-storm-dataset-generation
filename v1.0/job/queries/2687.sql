
WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
),
GenreCount AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id
),
CompanyInfo AS (
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
    m.title,
    m.production_year,
    COALESCE(r.role, 'Unknown Role') AS role,
    COALESCE(gc.keyword_count, 0) AS number_of_keywords,
    ci.companies,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = m.id AND cc.status_id = 1) AS complete_cast_count 
FROM 
    aka_title m
LEFT JOIN 
    MovieRoles r ON m.id = r.movie_id AND r.role_rank = 1
LEFT JOIN 
    GenreCount gc ON m.id = gc.movie_id
LEFT JOIN 
    CompanyInfo ci ON m.id = ci.movie_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND EXISTS (SELECT 1 FROM cast_info ci WHERE ci.movie_id = m.id AND ci.note IS NULL)
ORDER BY 
    m.production_year DESC, number_of_keywords DESC;
