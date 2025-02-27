WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY a.name) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        role_type rt ON mc.company_type_id = rt.id
    LEFT JOIN 
        aka_name a ON a.person_id = at.id 
    WHERE 
        a.name IS NOT NULL
)

SELECT 
    r.title_id,
    r.title,
    r.production_year,
    c.name AS company_name,
    STRING_AGG(DISTINCT rt.role, ', ') AS roles,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    MAX(rt.role) FILTER (WHERE rt.role IS NOT NULL) AS max_role,
    COUNT(ca.note) FILTER (WHERE ca.note IS NOT NULL) AS cast_notes_count,
    COALESCE(NULLIF(MAX(cn.country_code), ''), 'Unknown') AS company_country,
    CASE 
        WHEN r.rn = 1 THEN 'Top Movie of Year'
        ELSE 'Other Movie'
    END AS movie_rank
FROM 
    RankedMovies r
LEFT JOIN 
    movie_companies mc ON r.title_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON r.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast ca ON r.title_id = ca.movie_id
LEFT JOIN 
    movie_info mi ON r.title_id = mi.movie_id
LEFT JOIN 
    role_type rt ON ca.role_id = rt.id
GROUP BY 
    r.title_id, r.title, r.production_year, c.name, r.rn
ORDER BY 
    r.production_year DESC, keyword_count DESC, max_role DESC;
