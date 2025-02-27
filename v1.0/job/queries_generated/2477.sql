WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        c.movie_id,
        c.role_id,
        p.gender,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        person_info p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id, c.role_id, p.gender
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.actor_count,
    mc.company_name,
    mc.company_type,
    COALESCE(ca.name, 'No known alias') AS alias_name,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_details cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    movie_company_info mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    aka_title at ON rt.title_id = at.movie_id
LEFT JOIN 
    aka_name ca ON at.id = ca.id
LEFT JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
WHERE 
    rt.rn <= 5 AND (cd.gender = 'F' OR cd.gender IS NULL)
GROUP BY 
    rt.title, rt.production_year, cd.actor_count, mc.company_name, mc.company_type, ca.name
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 1
ORDER BY 
    rt.production_year DESC, rt.title;
