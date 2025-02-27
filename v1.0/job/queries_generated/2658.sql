WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.kind_id) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
), CompanyDetails AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        CASE 
            WHEN COUNT(DISTINCT mc.company_id) > 5 THEN 'Large Studio'
            ELSE 'Independent'
        END AS company_type
    FROM 
        movie_companies mc
    JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    cd.cast_count,
    cd.cast_names,
    co.company_count,
    co.company_type
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails cd ON rt.title = cd.movie_id
LEFT JOIN 
    CompanyDetails co ON rt.title = co.movie_id
WHERE 
    rt.title_rank <= 3
ORDER BY 
    rt.production_year DESC, rt.title;
