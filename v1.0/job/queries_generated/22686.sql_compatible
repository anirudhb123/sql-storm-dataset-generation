
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
completed_cast AS (
    SELECT 
        cc.movie_id,
        COUNT(cc.subject_id) AS num_cast_members,
        AVG(CASE WHEN cc.status_id = 1 THEN cc.subject_id END) AS avg_active_cast
    FROM 
        complete_cast cc
    GROUP BY 
        cc.movie_id
),
distinct_companies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        co.name AS company_name,
        n.name AS actor_name,
        nt.kind AS title_kind,
        kc.keyword AS title_keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name n ON ci.person_id = n.person_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        kind_type nt ON t.kind_id = nt.id
)
SELECT 
    tt.title,
    tt.production_year,
    tt.rn,
    tt.title_count,
    COALESCE(cc.num_cast_members, 0) AS num_cast_members,
    COALESCE(cc.avg_active_cast, 0) AS avg_active_cast,
    COALESCE(dc.num_companies, 0) AS num_companies,
    COALESCE(dc.companies, '') AS companies,
    STRING_AGG(DISTINCT ti.actor_name, ', ') AS actors,
    SUM(CASE WHEN ti.title_keyword IS NULL THEN 1 ELSE 0 END) AS null_keyword_count,
    MAX(CASE WHEN ti.title_keyword IS NOT NULL THEN ti.title_keyword END) AS last_title_keyword,
    COUNT(DISTINCT ti.title_id) FILTER (WHERE ti.title_keyword IS NOT NULL) AS unique_keyword_count
FROM 
    ranked_titles tt
LEFT JOIN 
    completed_cast cc ON tt.title_id = cc.movie_id
LEFT JOIN 
    distinct_companies dc ON tt.title_id = dc.movie_id
LEFT JOIN 
    title_info ti ON tt.title_id = ti.title_id
WHERE 
    tt.rn = 1
GROUP BY 
    tt.title, tt.production_year, tt.rn, tt.title_count, cc.num_cast_members, cc.avg_active_cast, dc.num_companies, dc.companies
ORDER BY 
    tt.production_year DESC;
