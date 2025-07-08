WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
CastByRole AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(CASE WHEN r.role = 'Lead' THEN 1 ELSE 0 END) AS has_lead
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
)
SELECT 
    rt.title,
    rt.production_year,
    cb.actor_count,
    cm.company_type,
    cm.company_name,
    (SELECT COUNT(*) 
     FROM movie_info AS mi 
     WHERE mi.movie_id = rt.title_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_count,
    COALESCE(NULLIF(rt.title, ''), 'Untitled') AS safe_title
FROM 
    RankedTitles AS rt
LEFT JOIN 
    CastByRole AS cb ON rt.title_id = cb.movie_id
LEFT JOIN 
    CompanyMovies AS cm ON rt.title_id = cm.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    cb.actor_count DESC NULLS LAST;
