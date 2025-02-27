WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CastAndRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        r.role AS role_name,
        COUNT(*) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, ci.person_id, r.role
),
MovieDetails AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        COALESCE(cr.role_name, 'Unknown') AS primary_role,
        CASE 
            WHEN MAX(cc.company_type_id) IS NULL THEN 'Independent'
            ELSE ct.kind
        END AS production_type
    FROM 
        RankedMovies r
    LEFT JOIN 
        CastAndRoles cr ON cr.movie_id = r.title_id
    LEFT JOIN 
        movie_companies cc ON cc.movie_id = r.title_id
    LEFT JOIN 
        company_type ct ON cc.company_type_id = ct.id
    GROUP BY 
        r.title_id, r.title, r.production_year, cr.role_name
)
SELECT 
    md.title,
    md.production_year,
    md.primary_role,
    md.production_type,
    COUNT(DISTINCT ki.keyword) AS keyword_count
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = md.title_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
GROUP BY 
    md.title, md.production_year, md.primary_role, md.production_type
HAVING 
    COUNT(DISTINCT ki.keyword) > 5
ORDER BY 
    md.production_year DESC, md.title ASC;
