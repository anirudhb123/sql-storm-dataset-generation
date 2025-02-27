WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND cn.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year
),
role_summary AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
final_results AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.aka_names,
        md.keywords,
        COALESCE(SUM(rs.role_count) FILTER (WHERE rs.role = 'Lead'), 0) AS lead_count,
        COALESCE(SUM(rs.role_count) FILTER (WHERE rs.role = 'Supporting'), 0) AS supporting_count 
    FROM 
        movie_details md
    LEFT JOIN 
        role_summary rs ON md.movie_id = rs.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.cast_count, md.aka_names, md.keywords
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    aka_names,
    keywords,
    lead_count,
    supporting_count
FROM 
    final_results
ORDER BY 
    production_year DESC, cast_count DESC;
