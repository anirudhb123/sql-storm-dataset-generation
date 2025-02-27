WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY SUM(ci.nr_order) DESC) AS title_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        a.title, a.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS production_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    t.title,
    t.production_year,
    ci.companies,
    ci.production_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM 
    RankedTitles t
LEFT JOIN 
    CompanyInfo ci ON t.title = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
WHERE 
    t.title_rank <= 5
    AND (ci.production_count > 0 OR ci.companies IS NOT NULL)
GROUP BY 
    t.title, t.production_year, ci.companies, ci.production_count
ORDER BY 
    t.production_year DESC, keyword_count DESC;
