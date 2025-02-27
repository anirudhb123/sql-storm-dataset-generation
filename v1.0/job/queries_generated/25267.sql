WITH movie_summary AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        COUNT(c.id) AS cast_count,
        COALESCE(SUM(CASE WHEN ci.kind_id = 2 THEN 1 ELSE 0 END), 0) AS actor_count,
        COALESCE(SUM(CASE WHEN ci.kind_id = 3 THEN 1 ELSE 0 END), 0) AS actress_count
    FROM
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    GROUP BY 
        t.id
),
company_summary AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT
    ms.title_id,
    ms.title,
    ms.production_year,
    ms.keywords,
    ms.cast_count,
    ms.actor_count,
    ms.actress_count,
    cs.companies,
    cs.company_count
FROM
    movie_summary ms
LEFT JOIN 
    company_summary cs ON ms.title_id = cs.movie_id
WHERE
    ms.production_year BETWEEN 2000 AND 2023
ORDER BY
    ms.production_year DESC,
    ms.cast_count DESC,
    ms.title;
