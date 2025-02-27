
WITH movie_statistics AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN c.role_id IS NULL THEN 0 ELSE 1 END) AS named_roles,
        COUNT(DISTINCT ko.keyword) AS total_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ko ON mk.keyword_id = ko.id
    GROUP BY 
        t.id, t.title
),
company_info AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT cn.id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        MAX(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS has_production_company
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
complex_analysis AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.total_cast,
        ms.named_roles,
        ms.total_keywords,
        ci.total_companies,
        ci.companies,
        ci.has_production_company,
        ROW_NUMBER() OVER (PARTITION BY ms.total_cast ORDER BY ms.total_keywords DESC) AS cast_ranking,
        (SELECT COUNT(*) FROM aka_title t2 WHERE t2.production_year = 2023) AS count_of_2023_titles
    FROM 
        movie_statistics ms
    JOIN 
        company_info ci ON ms.movie_id = ci.movie_id
)
SELECT 
    ca.movie_id,
    ca.title,
    ca.total_cast,
    ca.named_roles,
    ca.total_keywords,
    ca.total_companies,
    ca.companies,
    ca.has_production_company,
    ca.cast_ranking,
    EXISTS (SELECT 1 FROM complete_cast cc WHERE cc.movie_id = ca.movie_id AND cc.status_id = 3) AS has_completion_status,
    (SELECT AVG(total_cast) FROM movie_statistics) AS avg_cast_count,
    NULLIF((SELECT AVG(total_keywords) FROM movie_statistics), 0) AS avg_keywords_per_movie,
    CASE WHEN ca.named_roles > 3 THEN 'Diverse Cast' ELSE 'Small Cast' END AS cast_diversity,
    COALESCE(NULLIF(ca.has_production_company, 0), 0) AS production_company_existence
FROM 
    complex_analysis ca
WHERE 
    ca.named_roles > 0
ORDER BY 
    ca.total_keywords DESC, ca.movie_id ASC;
