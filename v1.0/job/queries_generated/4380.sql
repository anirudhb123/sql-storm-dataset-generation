WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_type_id) AS company_types_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tt.title_id,
    tt.title,
    tt.production_year,
    cd.total_cast,
    cd.cast_names,
    mc.company_names,
    mc.company_types_count,
    COALESCE(NULLIF(SUBSTRING_MIN(cd.cast_names), ''), 'No Cast Available') AS cast_info,
    CASE 
        WHEN mc.company_types_count = 0 THEN 'No Companies'
        ELSE 'Companies Present'
    END AS company_status
FROM 
    RankedTitles tt
LEFT JOIN 
    CastDetails cd ON tt.title_id = cd.movie_id
LEFT JOIN 
    MovieCompanies mc ON tt.title_id = mc.movie_id
WHERE 
    tt.title_rank = 1 
ORDER BY 
    tt.production_year DESC, 
    tt.title;
