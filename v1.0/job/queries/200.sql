WITH MovieSummary AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(a.name, ', ') AS top_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cp.name) AS company_count,
        STRING_AGG(cp.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cp ON mc.company_id = cp.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'duration' THEN mi.info END) AS duration,
        MAX(CASE WHEN it.info = 'genre' THEN mi.info END) AS genre
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.cast_count,
    ms.top_cast,
    cd.company_count,
    cd.companies,
    mi.duration,
    mi.genre
FROM 
    MovieSummary ms
LEFT JOIN 
    CompanyDetails cd ON ms.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON ms.movie_id = mi.movie_id
WHERE 
    ms.production_year IS NOT NULL
    AND (cd.company_count > 0 OR mi.genre IS NOT NULL)
ORDER BY 
    ms.production_year DESC, 
    ms.cast_count DESC
LIMIT 100;
