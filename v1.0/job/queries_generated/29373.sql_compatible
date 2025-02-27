
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT a.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name AS c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id 
    LEFT JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
role_summary AS (
    SELECT 
        ci.role_id,
        rc.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info AS ci
    LEFT JOIN 
        role_type AS rc ON ci.role_id = rc.id
    GROUP BY 
        ci.role_id, rc.role
),
detailed_movie_info AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.kind_id,
        rs.role,
        rs.role_count,
        md.aka_names,
        md.keywords,
        md.companies
    FROM 
        movie_details AS md
    LEFT JOIN 
        complete_cast AS cc ON md.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        role_summary AS rs ON ci.role_id = rs.role_id
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.aka_names,
    dmi.keywords,
    dmi.companies,
    SUM(dmi.role_count) AS total_roles,
    STRING_AGG(DISTINCT dmi.role, ', ') AS roles_list
FROM 
    detailed_movie_info AS dmi
GROUP BY 
    dmi.title, dmi.production_year, dmi.aka_names, dmi.keywords, dmi.companies
ORDER BY 
    dmi.production_year DESC, 
    dmi.title;
