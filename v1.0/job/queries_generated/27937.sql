WITH movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON mt.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    GROUP BY 
        mt.id
), 
role_statistics AS (
    SELECT 
        cc.movie_id,
        rt.role AS role,
        COUNT(cc.id) AS total_roles
    FROM 
        cast_info cc
    JOIN 
        role_type rt ON cc.person_role_id = rt.id
    GROUP BY 
        cc.movie_id, rt.role
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.companies,
    md.keywords,
    STRING_AGG(DISTINCT rs.role || ': ' || rs.total_roles ORDER BY rs.total_roles DESC) AS role_distribution
FROM 
    movie_details md
LEFT JOIN 
    role_statistics rs ON md.movie_id = rs.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.company_count, md.companies, md.keywords
ORDER BY 
    md.production_year DESC, md.title;
