WITH ranked_actors AS (
    SELECT 
        a.person_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
),
title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(k.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
completed_cast AS (
    SELECT 
        c.movie_id,
        COUNT(c.subject_id) AS complete_count
    FROM 
        complete_cast c
    GROUP BY 
        c.movie_id
)
SELECT 
    ti.title,
    ti.production_year,
    COALESCE(ra.name, 'Unknown Actor') AS lead_actor,
    ti.keyword_count,
    ci.companies,
    cc.complete_count
FROM 
    title_info ti
LEFT JOIN 
    ranked_actors ra ON ra.rn = 1 AND ra.person_id IN (SELECT person_id FROM cast_info ci WHERE ci.movie_id = ti.title_id)
LEFT JOIN 
    company_info ci ON ci.movie_id = ti.title_id
LEFT JOIN 
    completed_cast cc ON cc.movie_id = ti.title_id
WHERE 
    ti.production_year >= 2000 
    AND (ti.keyword_count > 5 OR ci.companies IS NOT NULL)
ORDER BY 
    ti.production_year DESC, 
    ti.title;
