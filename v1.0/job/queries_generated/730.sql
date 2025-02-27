WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        m.note
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
KeywordInfo AS (
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
    COALESCE(CAST(sr.role_count AS text), '0') AS total_cast,
    COALESCE(cd.company_name, 'Unknown') AS production_company,
    COALESCE(cd.company_type, 'N/A') AS company_type,
    COALESCE(ki.keywords, 'None') AS movie_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CastRoles sr ON rm.movie_id = sr.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    KeywordInfo ki ON rm.movie_id = ki.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, 
    total_cast DESC NULLS LAST;
