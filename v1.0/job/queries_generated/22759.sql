WITH RecursiveCTE AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        SUM(CASE WHEN ca.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_count
    FROM 
        cast_info ca
    INNER JOIN 
        title t ON ca.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        c.movie_id
), 

CompanyStats AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)

SELECT 
    t.title,
    t.production_year,
    r.total_cast,
    r.roles_count,
    c.company_name,
    c.company_type,
    (CASE 
        WHEN r.total_cast > 10 THEN 'Large Cast'
        WHEN r.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END) AS cast_size_category,
    (CASE 
        WHEN MAX(t.production_year) IS NULL THEN 'Year Unknown'
        ELSE 'Year Known'
    END) AS production_year_status,
    NULLIF(c.company_count, 0) AS unique_company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    title t
LEFT JOIN 
    RecursiveCTE r ON t.id = r.movie_id
LEFT JOIN 
    CompanyStats c ON t.id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    (t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%') OR 
    (t.production_year = 2023 AND t.title IS NOT NULL))
GROUP BY 
    t.title, t.production_year, r.total_cast, r.roles_count, c.company_name, c.company_type
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 0 OR c.company_count IS NOT NULL
ORDER BY 
    r.total_cast DESC NULLS LAST,
    t.production_year DESC,
    c.company_type ASC
FETCH FIRST 100 ROWS ONLY;
