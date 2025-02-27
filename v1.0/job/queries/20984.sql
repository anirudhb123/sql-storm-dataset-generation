
WITH movie_data AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS non_null_notes
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
company_info AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
extended_info AS (
    SELECT 
        mv.title_id,
        mv.title,
        mv.production_year,
        mv.keywords,
        mv.actor_count,
        mv.non_null_notes,
        ci.companies,
        ci.company_types,
        ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY mv.actor_count DESC) AS actor_rank
    FROM 
        movie_data mv
    LEFT JOIN 
        company_info ci ON mv.title_id = ci.movie_id
)
SELECT 
    ei.title,
    ei.production_year,
    ei.actor_count,
    ei.keywords,
    ei.companies,
    ei.company_types,
    ei.actor_rank,
    CASE 
        WHEN ei.actor_count > 5 THEN 'Blockbuster'
        WHEN ei.actor_count BETWEEN 3 AND 5 THEN 'Moderate Success'
        ELSE 'Indie'
    END AS movie_category,
    NULLIF(ei.companies[1], '') AS first_company,
    CASE 
        WHEN COUNT(DISTINCT ei.production_year) FILTER (WHERE ei.production_year IS NOT NULL) > 0 
        THEN 'Multi-Year Franchise' 
        ELSE 'Single Release' 
    END AS franchise_status
FROM 
    extended_info ei
WHERE 
    ei.non_null_notes > 0 
    AND ei.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ei.title, 
    ei.production_year, 
    ei.actor_count, 
    ei.keywords, 
    ei.companies, 
    ei.company_types, 
    ei.actor_rank
ORDER BY 
    ei.production_year DESC, 
    ei.actor_count DESC;
