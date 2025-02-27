WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        c.person_role_id,
        COALESCE(a.name, 'Unknown') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        MAX(ct.kind) AS company_kind
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON cn.id = mc.company_id
    INNER JOIN 
        company_type ct ON ct.id = mc.company_type_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ff.actor_name,
    ff.actor_order,
    ff.total_cast,
    mc.company_names,
    mc.company_kind,
    CASE 
        WHEN ff.total_cast > 10 THEN 'Large Cast'
        WHEN ff.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        WHEN ff.total_cast < 5 THEN 'Small Cast'
        ELSE 'Unknown'
    END AS cast_size_category
FROM 
    RankedTitles rt
LEFT JOIN 
    FilteredCast ff ON ff.movie_id = rt.title_id
LEFT JOIN 
    MovieCompanies mc ON mc.movie_id = rt.title_id
WHERE 
    rt.title_rank = 1
    AND (mc.company_kind IS NOT NULL OR mc.company_names IS NOT NULL)
ORDER BY 
    rt.production_year DESC, 
    ff.actor_order ASC NULLS LAST
LIMIT 100;