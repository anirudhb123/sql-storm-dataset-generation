WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
Actors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
)
SELECT 
    rt.title,
    rt.production_year,
    rt.cast_count,
    a.name AS actor_name,
    a.movie_count,
    cd.company_names,
    cd.company_type
FROM 
    RankedTitles rt
LEFT JOIN 
    Actors a ON rt.cast_count > 0 AND a.movie_count > 1
LEFT JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
WHERE 
    rt.rn <= 5 
    AND (a.movie_count IS NULL OR a.movie_count > 2)
ORDER BY 
    rt.production_year DESC, rt.cast_count DESC;
