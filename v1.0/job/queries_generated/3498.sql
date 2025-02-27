WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
),
cast_info_with_names AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        a.name AS actor_name,
        ci.role_id,
        ci.nr_order,
        COALESCE(p.info, 'No Info') AS role_info
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
    ARRAY_AGG(DISTINCT c.actor_name) AS actors,
    COUNT(DISTINCT ci.role_id) AS unique_roles,
    MAX(md.keyword_rank) AS max_keyword_rank
FROM 
    movie_details md
LEFT JOIN 
    cast_info_with_names c ON md.movie_id = c.movie_id
LEFT JOIN 
    (SELECT movie_id, keyword, ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY keyword) AS keyword_order 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id) kw ON md.movie_id = kw.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year
HAVING 
    COUNT(DISTINCT c.role_id) > 2
ORDER BY 
    md.production_year DESC, max_keyword_rank ASC;
