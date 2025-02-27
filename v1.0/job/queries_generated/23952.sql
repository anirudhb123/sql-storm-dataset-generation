WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year > (SELECT AVG(production_year) FROM aka_title)
),
CompanyRoles AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ci.role AS company_role,
        COALESCE(mc.note, 'No note provided') AS note_provided
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        comp_cast_type ci ON mc.company_type_id = ci.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cr.company_name,
    cr.company_type,
    cr.company_role,
    mk.keywords,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = rm.movie_id) AS total_cast,
    CASE 
        WHEN rm.production_year IS NULL THEN 'Year unknown'
        WHEN rm.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS era_classification
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyRoles cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    (cr.company_name IS NOT NULL OR mk.keywords IS NOT NULL)
    AND rm.rn <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC
