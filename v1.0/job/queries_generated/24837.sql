WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS yearly_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieCredits AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN c.person_role_id IS NULL THEN 0 ELSE 1 END) AS credited_cast
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    COALESCE(mc.company_names, 'No Companies') AS companies_involved,
    COALESCE(mc.total_cast, 0) AS total_cast,
    CASE 
        WHEN mc.total_cast > 0 THEN (mc.credited_cast::float / mc.total_cast) * 100
        ELSE NULL 
    END AS credited_percentage
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieCredits mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    MovieCompanies mco ON rt.title_id = mco.movie_id
WHERE 
    rt.yearly_rank <= 5 
    AND rt.title ILIKE '%dark%' 
ORDER BY 
    rt.production_year DESC, rt.title;
