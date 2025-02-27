
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT ci.person_role_id) AS role_count,
        COUNT(DISTINCT mi.info) AS info_count
    FROM 
        title t
    INNER JOIN 
        movie_info mi ON t.id = mi.movie_id
    INNER JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    INNER JOIN 
        complete_cast cc ON t.id = cc.movie_id
    INNER JOIN 
        cast_info ci ON cc.subject_id = ci.id
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    INNER JOIN 
        movie_companies mc ON t.id = mc.movie_id
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    movie_id,
    title,
    production_year,
    keywords,
    company_names,
    actors,
    role_count,
    info_count
FROM 
    movie_details
ORDER BY 
    production_year DESC, role_count DESC;
