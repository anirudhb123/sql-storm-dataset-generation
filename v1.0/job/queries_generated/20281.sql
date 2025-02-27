WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RAND()) AS random_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        c.role_id,
        COUNT(*) AS role_count,
        STRING_AGG(r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, c.role_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        ct.kind AS company_kind
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id, ct.kind
),
CompleteInfo AS (
    SELECT 
        t.title, 
        rt.production_year,
        ar.roles,
        mk.keywords,
        fc.company_names,
        fc.company_kind,
        ARRAY_AGG(DISTINCT ci.note) FILTER (WHERE ci.note IS NOT NULL) AS cast_notes
    FROM 
        RankedTitles rt
    LEFT JOIN 
        ActorRoles ar ON rt.title_id = ar.role_id
    LEFT JOIN 
        MovieKeywords mk ON rt.title_id = mk.movie_id
    LEFT JOIN 
        FilteredCompanies fc ON rt.title_id = fc.movie_id
    LEFT JOIN 
        complete_cast ci ON rt.title_id = ci.movie_id
    GROUP BY 
        rt.title, rt.production_year, ar.roles, mk.keywords, fc.company_names, fc.company_kind
)
SELECT 
    title, 
    production_year,
    COALESCE(roles, 'No roles available') AS roles,
    COALESCE(keywords, 'No keywords available') AS keywords,
    COALESCE(company_names, 'No company information') AS company_names,
    COALESCE(ARRAY_TO_STRING(cast_notes, '; '), 'No cast notes available') AS cast_notes
FROM 
    CompleteInfo
WHERE 
    (production_year > 2000 OR roles IS NOT NULL)
    AND (keywords IS NULL OR company_kind LIKE '%Distributor%')
ORDER BY 
    production_year DESC, title;
