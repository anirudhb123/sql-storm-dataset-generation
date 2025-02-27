WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND cc.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        cn.country_code = 'USA' 
        AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),
RoleDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS num_roles,
        SUM(CASE WHEN r.role LIKE 'Lead%' THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.cast_names,
    rd.num_roles,
    rd.lead_roles,
    CONCAT(md.production_year, ': ', md.movie_title) AS info_header
FROM 
    MovieDetails md
JOIN 
    RoleDetails rd ON md.movie_id = rd.movie_id
ORDER BY 
    md.production_year DESC, md.movie_title;
