WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.kind || ': ' || cn.name) AS companies
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        aka_name AS ak ON t.id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
role_distribution AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS rt ON ci.person_role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
final_benchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.aka_names,
        md.keywords,
        md.companies,
        COALESCE(SUM(CASE WHEN rd.role = 'Lead' THEN rd.role_count ELSE 0 END), 0) AS lead_count,
        COALESCE(SUM(CASE WHEN rd.role = 'Supporting' THEN rd.role_count ELSE 0 END), 0) AS supporting_count,
        COALESCE(SUM(CASE WHEN rd.role = 'Cameo' THEN rd.role_count ELSE 0 END), 0) AS cameo_count
    FROM 
        movie_details AS md
    LEFT JOIN 
        role_distribution AS rd ON md.movie_id = rd.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.aka_names, md.keywords, md.companies
)
SELECT 
    *,
    (lead_count + supporting_count + cameo_count) AS total_casting
FROM 
    final_benchmark
WHERE 
    production_year BETWEEN 2000 AND 2020
ORDER BY 
    total_casting DESC, production_year DESC;
