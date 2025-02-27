WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS production_companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastRoles AS (
    SELECT 
        movie_id,
        role_id,
        COUNT(*) AS role_count
    FROM 
        cast_info
    GROUP BY 
        movie_id, role_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.cast_count, 0) AS cast_count,
    COALESCE(md.actors, 'None') AS actors,
    COALESCE(cd.production_companies, 'Unknown') AS production_companies,
    COALESCE(cd.company_count, 0) AS company_count,
    COALESCE(mk.keywords, 'None') AS keywords,
    SUM(cr.role_count) AS total_roles,
    CASE 
        WHEN md.production_year IS NULL THEN 'Year Unknown'
        WHEN md.production_year < 2000 THEN 'Classic'
        ELSE 'Modern' 
    END AS era,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    CastRoles cr ON md.movie_id = cr.movie_id
WHERE 
    (md.cast_count IS NOT NULL OR cd.company_count IS NOT NULL) 
    AND (md.production_year >= 1990 AND md.production_year < 2024)
ORDER BY 
    md.production_year DESC,
    rank
LIMIT 50;
