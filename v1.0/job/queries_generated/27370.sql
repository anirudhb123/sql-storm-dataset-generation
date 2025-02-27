WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS cast_names,
        cst.kind AS cast_role
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        role_type cst ON ci.role_id = cst.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, cst.kind
),
company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
complete_details AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keyword,
        md.cast_role,
        cd.company_name,
        cd.company_type,
        cd.num_movies
    FROM 
        movie_details md
    LEFT JOIN 
        company_details cd ON md.movie_id = cd.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_names,
    keyword,
    cast_role,
    company_name,
    company_type,
    num_movies
FROM 
    complete_details
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, title;
