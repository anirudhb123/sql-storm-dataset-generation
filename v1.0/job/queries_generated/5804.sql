WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        ct.kind AS company_type,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, c.name, ct.kind
),
PersonCast AS (
    SELECT 
        ci.movie_id,
        p.name AS person_name,
        rt.role
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_name,
    md.company_type,
    md.aka_names,
    md.keywords,
    pc.person_name,
    pc.role
FROM 
    MovieData md
LEFT JOIN 
    PersonCast pc ON md.movie_id = pc.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
