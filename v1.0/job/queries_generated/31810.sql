WITH RECURSIVE CompanyHierarchy AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        1 AS level
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL

    UNION ALL

    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ch.level + 1
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        CompanyHierarchy ch ON mc.movie_id = ch.movie_id
)
SELECT 
    title.title,
    title.production_year,
    STRING_AGG(DISTINCT ch.company_name, ', ') AS companies_involved,
    COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS actor_count,
    AVG(NULLIF(movie_info.info::integer, 0)) AS average_info_metric,
    ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
FROM 
    aka_title title
LEFT JOIN 
    cast_info ci ON title.movie_id = ci.movie_id
LEFT JOIN 
    CompanyHierarchy ch ON title.movie_id = ch.movie_id
LEFT JOIN 
    movie_info mi ON title.movie_id = mi.movie_id
WHERE 
    title.production_year > 2000 
    AND title.kind_id = (SELECT id FROM kind_type WHERE kind='movie')
    AND (mi.info_type_id IN (SELECT id FROM info_type WHERE info='Budget') AND mi.info IS NOT NULL)
GROUP BY 
    title.id, title.title, title.production_year
HAVING 
    AVG(NULLIF(movie_info.info::integer, 0)) > 1000000
ORDER BY 
    title.production_year DESC, actor_count DESC;
