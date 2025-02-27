WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
CompanyMovies AS (
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
    WHERE 
        c.country_code IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        a.surname_pcode,
        c.kind AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type c ON ci.role_id = c.id
),
MovieInfoWithKeywords AS (
    SELECT 
        mi.movie_id,
        mi.info,
        k.keyword
    FROM 
        movie_info mi
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rm.title,
    rm.production_year,
    cm.company_name,
    cm.company_type,
    cd.actor_name,
    cd.role_name,
    mk.info,
    mk.keyword,
    COALESCE(NULLIF(CAST(cd.cast_order AS TEXT), '1'), 'Feature Ensemble') AS ensemble,
    CASE 
        WHEN cd.surname_pcode IS NULL THEN 'Unknown Surname Code'
        ELSE cd.surname_pcode
    END AS surname_code,
    CASE 
        WHEN mk.info IS NULL AND mk.keyword IS NULL THEN 'No Additional Information'
        ELSE COALESCE(mk.info, mk.keyword, 'N/A')
    END AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfoWithKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.year_rank <= 5
    AND (cm.company_type IS NOT NULL OR cd.role_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
