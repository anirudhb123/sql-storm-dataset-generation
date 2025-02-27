WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS alias_names,
        STRING_AGG(DISTINCT co.name, ', ') AS production_companies
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        t.id
),
cast_details AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(CONCAT(n.name, ' (', rt.role, ')'), ', ') AS cast_info
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        name n ON ci.person_id = n.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        t.id
),
keyword_details AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    md.movie_title, 
    md.production_year,
    md.alias_names,
    cd.cast_info,
    kd.keywords
FROM 
    movie_details md
LEFT JOIN 
    cast_details cd ON md.id = cd.movie_id
LEFT JOIN 
    keyword_details kd ON md.id = kd.movie_id
ORDER BY 
    md.production_year DESC;
