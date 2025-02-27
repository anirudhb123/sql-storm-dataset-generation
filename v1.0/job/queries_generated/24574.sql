WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL 
        AND t.title IS NOT NULL
),
TopRankedTitles AS (
    SELECT 
        rt.*
    FROM 
        RankedTitles rt
    WHERE 
        rt.year_rank <= 3
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS distinct_roles,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FullMovieInfo AS (
    SELECT 
        tt.title_id,
        tt.title,
        tt.production_year,
        cr.distinct_roles,
        cr.note_count,
        ci.company_names,
        ci.company_types
    FROM 
        TopRankedTitles tt
    LEFT JOIN 
        CastRoles cr ON tt.title_id = cr.movie_id
    LEFT JOIN 
        CompanyInfo ci ON tt.title_id = ci.movie_id
)
SELECT 
    fmi.title_id,
    fmi.title,
    fmi.production_year,
    COALESCE(fmi.distinct_roles, 0) AS distinct_roles,
    COALESCE(fmi.note_count, 0) AS note_count,
    COALESCE(fmi.company_names, 'None') AS company_names,
    COALESCE(fmi.company_types, 'None') AS company_types,
    CASE
        WHEN fmi.note_count > 1 THEN 'High Note Activity'
        WHEN fmi.note_count = 1 THEN 'Single Note Activity'
        ELSE 'No Note Activity'
    END AS note_activity_label
FROM 
    FullMovieInfo fmi
ORDER BY 
    fmi.production_year DESC, 
    fmi.title;

-- Additional complexity through NULL checking and handlings
SELECT 
    *,
    CASE 
        WHEN company_names IS NULL THEN 'No Companies'
        WHEN company_names LIKE '%Production%' THEN 'Involves Production'
        ELSE 'Various Companies'
    END AS company_status
FROM 
    FullMovieInfo
WHERE 
    production_year BETWEEN 1990 AND 2020
    AND (distinct_roles IS NULL OR note_count > 0)
    AND NOT EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = FullMovieInfo.title_id 
        AND mi.info LIKE '%Sequel%'
    )
ORDER BY 
    title ASC;
