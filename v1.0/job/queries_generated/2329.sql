WITH movie_summary AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON ci.movie_id = at.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.id, at.title, at.production_year
),
keyword_summary AS (
    SELECT 
        mt.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mt.id = mk.movie_id
    GROUP BY 
        mt.movie_id
),
movie_company_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        mc.movie_id
),
final_summary AS (
    SELECT 
        ms.movie_title,
        ms.production_year,
        ms.total_cast,
        ms.avg_roles,
        COALESCE(ks.keyword_count, 0) AS keyword_count,
        COALESCE(cs.company_count, 0) AS company_count,
        ms.cast_names,
        cs.companies
    FROM 
        movie_summary ms
    LEFT JOIN 
        keyword_summary ks ON ms.movie_title = (SELECT title FROM aka_title WHERE id = ks.movie_id)
    LEFT JOIN 
        movie_company_summary cs ON ms.movie_title = (SELECT title FROM aka_title WHERE id = cs.movie_id)
)
SELECT 
    movie_title,
    production_year,
    total_cast,
    avg_roles,
    keyword_count,
    company_count,
    cast_names,
    companies
FROM 
    final_summary
ORDER BY 
    production_year DESC, total_cast DESC;
