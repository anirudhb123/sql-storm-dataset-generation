
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.company_name,
    cd.company_type,
    mk.keywords,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    MAX(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE ci.nr_order END) AS max_order
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    ci.role_id IS NOT NULL
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, cd.company_name, cd.company_type, mk.keywords
HAVING 
    COALESCE(COUNT(DISTINCT ci.person_id), 0) > 0
ORDER BY 
    rm.production_year DESC, rm.title ASC;
