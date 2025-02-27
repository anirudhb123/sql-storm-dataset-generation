WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS company_names
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name AS c ON mc.company_id = c.id
    LEFT JOIN 
        aka_name AS ak ON ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = m.id)
    GROUP BY 
        m.id
),

cast_roles AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT rt.role) AS roles,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)

SELECT 
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.keywords,
    cr.roles,
    cr.cast_count
FROM 
    movie_details AS md
JOIN 
    cast_roles AS cr ON md.movie_id = cr.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
