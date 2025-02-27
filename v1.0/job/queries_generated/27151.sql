WITH ranked_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        a.title AS aka_title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY LENGTH(at.title) DESC) AS title_rank
    FROM 
        aka_title at
    LEFT JOIN 
        aka_name a ON at.id = a.id
),
person_movie_roles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        r.role AS role_name,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id, ci.movie_id, r.role
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    pt.movie_id,
    pt.role_name,
    pt.role_count,
    md.title,
    md.production_year,
    md.company_count,
    ARRAY_TO_STRING(md.keywords, ', ') AS keywords,
    rt.title AS ranked_aka_title,
    rt.title_rank
FROM 
    person_movie_roles pt
JOIN 
    movie_details md ON pt.movie_id = md.movie_id
JOIN 
    ranked_titles rt ON md.title = rt.title
WHERE 
    rt.title_rank <= 5
ORDER BY 
    pt.role_count DESC, md.production_year DESC;
