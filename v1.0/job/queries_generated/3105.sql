WITH movie_summary AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(t.title, 'Unknown Title') AS title,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        title m ON t.movie_id = m.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        role_type ci ON c.role_id = ci.id
    GROUP BY 
        m.id, t.title
), 
company_stats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
final_report AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.cast_count,
        cs.company_count,
        cs.companies,
        ms.keywords,
        CASE 
            WHEN ms.cast_count > 5 THEN 'Blockbuster' 
            WHEN ms.cast_count BETWEEN 1 AND 5 THEN 'Indie' 
            ELSE 'Unknown' 
        END AS category
    FROM 
        movie_summary ms
    LEFT JOIN 
        company_stats cs ON ms.movie_id = cs.movie_id
)
SELECT 
    movie_id,
    title,
    cast_count,
    company_count,
    companies,
    keywords,
    category,
    ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
FROM 
    final_report
WHERE 
    category != 'Unknown'
ORDER BY 
    cast_count DESC, title ASC;
