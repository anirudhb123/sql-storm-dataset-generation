WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        aka_title ak ON ak.movie_id = t.id
    GROUP BY 
        t.id
),
cast_details AS (
    SELECT 
        t.id AS title_id,
        c.person_id,
        p.name AS person_name,
        r.role AS person_role
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        name p ON c.person_id = p.id
    JOIN 
        role_type r ON c.role_id = r.id
),
complete_details AS (
    SELECT 
        md.movie_title,
        md.production_year,
        cd.person_name,
        cd.person_role,
        md.aka_names,
        md.keywords,
        md.companies
    FROM 
        movie_details md
    JOIN 
        cast_details cd ON md.movie_title = cd.title_id
)
SELECT 
    c.title_id,
    c.person_name,
    c.person_role,
    d.movie_title,
    d.production_year,
    d.aka_names,
    d.keywords,
    d.companies
FROM 
    complete_details d
JOIN 
    cast_details c ON d.movie_title = c.title_id
ORDER BY 
    d.production_year DESC, 
    c.person_name;
