WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM 
        title m
    WHERE 
        m.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(CASE WHEN r.role = 'actor' THEN 1 END) AS actor_count,
        COUNT(CASE WHEN r.role = 'director' THEN 1 END) AS director_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    cd.actor_count,
    cd.director_count,
    ci.company_name,
    ci.company_type
FROM 
    RankedMovies r
LEFT JOIN 
    CastDetails cd ON r.movie_id = cd.movie_id
LEFT JOIN 
    CompanyInfo ci ON r.movie_id = ci.movie_id
WHERE 
    (cd.actor_count IS NOT NULL OR cd.director_count IS NOT NULL)
    AND r.rn <= 10
ORDER BY 
    r.production_year DESC, 
    r.title ASC;
