WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        ct.kind AS company_type,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, c.name, ct.kind
),

cast_details AS (
    SELECT 
        t.title AS movie_title,
        ARRAY_AGG(DISTINCT n.name) AS cast_names,
        ARRAY_AGG(DISTINCT rt.role) AS roles
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id 
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role IS NOT NULL
    GROUP BY 
        t.title
)

SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.company_type,
    md.aka_names,
    md.keywords,
    cd.cast_names,
    cd.roles
FROM 
    movie_details md
LEFT JOIN 
    cast_details cd ON md.movie_title = cd.movie_title
ORDER BY 
    md.production_year DESC, md.movie_title;
