WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT a.name) AS cast_names,
        COUNT(DISTINCT cc.person_id) AS total_cast
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
PersonInfo AS (
    SELECT 
        p.id AS person_id,
        p.gender,
        ri.role AS role,
        GROUP_CONCAT(DISTINCT pi.info) AS additional_info
    FROM 
        name p
    JOIN 
        cast_info ci ON p.id = ci.person_id
    JOIN 
        role_type ri ON ci.role_id = ri.id
    LEFT JOIN 
        person_info pi ON p.id = pi.person_id
    GROUP BY 
        p.id, p.gender, ri.role
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.company_name,
    md.cast_names,
    md.total_cast,
    pi.person_id,
    pi.gender,
    pi.role,
    pi.additional_info
FROM 
    MovieDetails md
JOIN 
    PersonInfo pi ON md.cast_names LIKE '%' || pi.person_id || '%'
ORDER BY 
    md.production_year DESC, md.title;
