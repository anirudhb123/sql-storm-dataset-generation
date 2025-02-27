WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS TitleRank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
CalibratedCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_member_count,
        MAX(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note,
        MAX(CASE WHEN ci.role_id IS NOT NULL THEN ci.note ELSE 'No Role' END) AS last_note_role
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        cs.company_count,
        cs.companies,
        cc.cast_member_count,
        cc.has_note,
        cc.last_note_role
    FROM 
        RankedTitles t
    LEFT JOIN 
        CompanyStats cs ON t.id = cs.movie_id
    LEFT JOIN 
        CalibratedCast cc ON t.id = cc.movie_id
    WHERE 
        t.TitleRank = 1
)
SELECT 
    md.title,
    md.production_year,
    kt.keyword,
    md.company_count,
    md.cast_member_count,
    COALESCE(md.has_note, 0) AS has_note,
    COALESCE(md.last_note_role, 'Unspecified') AS last_note_role
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    (md.production_year BETWEEN 2000 AND 2023) 
    AND (md.company_count IS NOT NULL OR md.cast_member_count > 5)
ORDER BY 
    md.production_year DESC, md.title ASC
FETCH FIRST 50 ROWS ONLY;
