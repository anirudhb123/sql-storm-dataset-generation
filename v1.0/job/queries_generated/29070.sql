WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        p.gender AS primary_gender,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT CASE WHEN ci.kind_id IS NOT NULL THEN ci.kind_id END) AS role_types
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name p ON c.person_id = p.person_id
    LEFT JOIN 
        role_type ci ON c.role_id = ci.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, p.gender
),
company_data AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.keywords,
    md.primary_gender,
    md.cast_count,
    md.role_types,
    cd.company_names,
    cd.company_count
FROM 
    movie_data md
LEFT JOIN 
    company_data cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.cast_count DESC, 
    md.movie_title;
