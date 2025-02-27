WITH movie_data AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        AVG(COALESCE(ca.nr_order, 0)) AS avg_cast_order,
        COUNT(DISTINCT ca.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, mk.keyword
), 
company_data AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
cast_performance AS (
    SELECT 
        cd.title_id, 
        cd.title,
        SUM(CASE WHEN ROLE.role = 'Lead' THEN 1 ELSE 0 END) AS lead_roles,
        SUM(CASE WHEN ROLE.role = 'Supporting' THEN 1 ELSE 0 END) AS supporting_roles
    FROM 
        movie_data cd
    LEFT JOIN 
        cast_info ci ON cd.title_id = ci.movie_id
    LEFT JOIN 
        role_type ROLE ON ci.role_id = ROLE.id
    GROUP BY 
        cd.title_id, cd.title
)
SELECT 
    md.title AS Movie_Title,
    md.production_year AS Production_Year,
    md.keyword AS Keyword,
    cd.total_companies AS Company_Count,
    cd.company_names AS Companies,
    cp.lead_roles,
    cp.supporting_roles,
    COALESCE(md.avg_cast_order, 0) AS Average_Cast_Order,
    md.total_cast AS Total_Cast
FROM 
    movie_data md
LEFT JOIN 
    company_data cd ON md.title_id = cd.movie_id
LEFT JOIN 
    cast_performance cp ON md.title_id = cp.title_id
WHERE 
    md.production_year >= 2000 AND
    (md.total_cast IS NULL OR md.total_cast > 5) AND
    (cp.lead_roles + cp.supporting_roles) > 0
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 10;
