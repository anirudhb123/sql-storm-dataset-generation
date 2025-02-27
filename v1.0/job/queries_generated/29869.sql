WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS companies,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        COUNT(DISTINCT a.id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id
),
info_details AS (
    SELECT 
        m.movie_id,
        STRING_AGG(CONCAT(i.info_type_id, ': ', m.info), '; ') AS info 
    FROM 
        movie_info m
    LEFT JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    md.roles,
    md.actor_count,
    id.info
FROM 
    movie_details md
LEFT JOIN 
    info_details id ON md.movie_id = id.movie_id
WHERE 
    md.production_year >= 2000 
ORDER BY 
    md.actor_count DESC
LIMIT 50;
