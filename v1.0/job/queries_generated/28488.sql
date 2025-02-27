WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COALESCE(td.role_count, 0) AS role_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN (
        SELECT 
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS role_count
        FROM 
            cast_info ci
        GROUP BY 
            ci.movie_id
    ) td ON t.id = td.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_summary AS (
    SELECT 
        k.keyword,
        COUNT(m.movie_id) AS movie_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        k.keyword
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.companies,
    md.keywords,
    md.role_count,
    COALESCE(ks.movie_count, 0) AS keyword_usage
FROM 
    movie_details md
LEFT JOIN 
    keyword_summary ks ON md.keywords LIKE '%' || ks.keyword || '%'
ORDER BY 
    md.production_year DESC, md.title;
