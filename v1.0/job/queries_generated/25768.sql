WITH movie_data AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aka_names,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS company_names,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword SEPARATOR ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = mt.movie_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.movie_id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
person_roles AS (
    SELECT 
        ci.person_id,
        r.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON r.id = ci.role_id
    GROUP BY 
        ci.person_id, r.role
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.company_names,
    md.keywords,
    pr.role,
    pr.role_count
FROM 
    movie_data md
LEFT JOIN 
    person_roles pr ON pr.person_id IN (
        SELECT DISTINCT ci.person_id 
        FROM cast_info ci WHERE ci.movie_id = md.movie_id
    )
ORDER BY 
    md.production_year DESC, md.movie_title;
