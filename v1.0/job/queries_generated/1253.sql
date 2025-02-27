WITH movie_stats AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        AVG(CASE WHEN ca.nr_order IS NOT NULL THEN ca.nr_order ELSE NULL END) AS avg_cast_order,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords,
        MAX(ci.company_type_id) AS max_company_type_id
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ca ON m.id = ca.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title
),
keyword_stats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_stats AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.total_cast,
        ms.avg_cast_order,
        COALESCE(ks.keywords_list, 'No Keywords') AS keywords,
        COALESCE(ms.total_keywords, 0) AS total_keywords,
        ms.max_company_type_id
    FROM 
        movie_stats ms
    LEFT JOIN 
        keyword_stats ks ON ms.movie_id = ks.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.total_cast,
    f.avg_cast_order,
    f.keywords,
    f.total_keywords,
    ct.kind AS company_type
FROM 
    final_stats f
LEFT JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    f.total_cast > 1 AND 
    f.avg_cast_order IS NOT NULL
ORDER BY 
    f.total_cast DESC, 
    f.avg_cast_order ASC;
