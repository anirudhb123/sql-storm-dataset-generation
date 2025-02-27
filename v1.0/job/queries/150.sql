WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        title t
)
SELECT 
    ak.name AS actor_name,
    rt.title,
    rt.production_year,
    COALESCE(ck.keyword, 'No Keywords') AS keyword,
    COUNT(ci.id) AS role_count,
    AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS has_notes_percentage,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    ranked_titles rt ON ci.movie_id = rt.title_id
LEFT JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    keyword ck ON mk.keyword_id = ck.id
LEFT JOIN 
    movie_companies mc ON rt.title_id = mc.movie_id
WHERE 
    ak.name IS NOT NULL
    AND rt.rank_by_year <= 5
GROUP BY 
    ak.name, rt.title, rt.production_year, ck.keyword
HAVING 
    COUNT(ci.id) > 1
ORDER BY 
    rt.production_year DESC, actor_name;
