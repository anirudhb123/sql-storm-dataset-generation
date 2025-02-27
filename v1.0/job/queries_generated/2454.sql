WITH movie_summary AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_filled
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        a.title, a.production_year
),
company_summary AS (
    SELECT 
        m.movie_id,
        COALESCE(cn.name, 'Unknown') AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    LEFT JOIN 
        company_name cn ON m.company_id = cn.id
    LEFT JOIN 
        company_type ct ON m.company_type_id = ct.id
),
keyword_summary AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.cast_names,
    ms.roles_filled,
    cs.company_name,
    cs.company_type,
    ks.keywords
FROM 
    movie_summary ms
LEFT JOIN 
    company_summary cs ON ms.title = (SELECT title FROM aka_title WHERE id = cs.movie_id)
LEFT JOIN 
    keyword_summary ks ON ms.production_year = (SELECT production_year FROM aka_title WHERE id = ks.movie_id)
WHERE 
    ms.total_cast > 0 
    AND (ks.keywords IS NOT NULL OR ks.keywords IS NOT NULL)
ORDER BY 
    ms.production_year DESC, ms.total_cast DESC
LIMIT 50;
