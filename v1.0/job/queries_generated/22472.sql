WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        row_number() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(DISTINCT keyword.keyword) OVER (PARTITION BY at.id) AS keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ON mk.keyword_id = keyword.id
    WHERE 
        at.production_year > (SELECT AVG(production_year) FROM aka_title) 
        AND at.title IS NOT NULL
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS average_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
companies_with_titles AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
final_output AS (
    SELECT 
        rt.title,
        rt.production_year,
        cs.actor_count,
        cs.average_order,
        ct.companies,
        CASE 
            WHEN rt.keyword_count = 0 THEN 'No Keywords'
            ELSE 'Keywords Present'
        END AS keyword_status
    FROM 
        ranked_titles rt
    LEFT JOIN 
        cast_summary cs ON rt.id = cs.movie_id
    LEFT JOIN 
        companies_with_titles ct ON rt.id = ct.movie_id
)
SELECT 
    title,
    production_year,
    actor_count,
    average_order,
    companies,
    keyword_status
FROM 
    final_output
WHERE 
    (actor_count IS NULL OR actor_count > 10) 
    AND (keyword_status = 'Keywords Present' OR production_year < 2000)
ORDER BY 
    production_year DESC, actor_count DESC, title;
