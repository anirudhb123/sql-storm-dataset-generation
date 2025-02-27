WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rn,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_per_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        ct.kind AS role_type,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.movie_id, ct.kind
)
SELECT 
    rt.title,
    rt.production_year,
    cr.role_type,
    cr.role_count,
    COALESCE(NULLIF(rt.total_per_year, 0), 1) AS non_zero_total,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
FROM 
    RankedTitles rt
LEFT JOIN 
    complete_cast cc ON rt.id = cc.movie_id
LEFT JOIN 
    cast_roles cr ON cc.movie_id = cr.movie_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
WHERE 
    rt.production_year BETWEEN 2000 AND 2020
    AND (cr.role_count IS NULL OR cr.role_count > 1)
GROUP BY 
    rt.title, rt.production_year, cr.role_type, cr.role_count
ORDER BY 
    rt.production_year DESC, rt.title;
