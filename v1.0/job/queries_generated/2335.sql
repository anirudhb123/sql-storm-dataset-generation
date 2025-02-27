WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
TitleWithKeywords AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedTitles rt
    LEFT JOIN 
        movie_keyword mk ON rt.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rt.title_id, rt.title, rt.production_year
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ct.kind, ', ') AS cast_types
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.movie_id
),
FinalReport AS (
    SELECT 
        twk.title_id,
        twk.title,
        twk.production_year,
        COALESCE(cr.total_cast, 0) AS cast_count,
        COALESCE(cr.cast_types, 'N/A') AS cast_roles,
        twk.keywords
    FROM 
        TitleWithKeywords twk
    LEFT JOIN 
        CastRoles cr ON twk.title_id = cr.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.cast_roles,
    fr.keywords,
    CASE 
        WHEN fr.cast_count = 0 THEN 'No Cast'
        WHEN fr.production_year < 2000 THEN 'Classic Movie'
        ELSE 'Modern Movie'
    END AS movie_category
FROM 
    FinalReport fr
WHERE 
    fr.production_year > 1990
ORDER BY 
    fr.production_year DESC, fr.title;
