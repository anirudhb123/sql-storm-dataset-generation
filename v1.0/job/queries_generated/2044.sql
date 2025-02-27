WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        t.production_year IS NOT NULL
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.cast_count,
        cs.company_count,
        COALESCE(cs.company_names, 'No Companies') AS company_names
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CompanyStats cs ON rt.movie_id = cs.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.company_count,
    md.company_names
FROM 
    MovieDetails md
WHERE 
    md.cast_count > 5 
    AND md.company_count IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = md.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
        AND mi.info IS NOT NULL
    )
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
