WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT c.name) AS company_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords,
        STRING_AGG(DISTINCT p.info, '; ') AS person_info
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name ak ON ak.id = at.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year
),
movie_cast AS (
    SELECT 
        t.id AS movie_id,
        COUNT(DISTINCT ci.id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT_WS(', ', ak.name, rt.role), '; ') AS cast_names_and_roles
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        role_type rt ON rt.id = ci.role_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id
)
SELECT 
    md.title,
    md.production_year,
    md.aka_names,
    md.company_names,
    md.movie_keywords,
    mc.total_cast,
    mc.cast_names_and_roles
FROM 
    movie_details md
LEFT JOIN 
    movie_cast mc ON md.title = (
        SELECT title 
        FROM title 
        WHERE id = mc.movie_id
    )
ORDER BY 
    md.production_year DESC, 
    md.title;
