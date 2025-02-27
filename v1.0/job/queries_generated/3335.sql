WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
), 
CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(cc.id) AS total_cast,
        COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS credited_cast
    FROM 
        complete_cast cc
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        cc.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mk.keywords,
    cd.company_name,
    cd.company_type,
    cc.total_cast,
    cc.credited_cast,
    (cc.total_cast - cc.credited_cast) AS uncredited_cast,
    CASE 
        WHEN cc.total_cast > 0 THEN (CAST(cc.credited_cast AS FLOAT) / cc.total_cast) * 100 
        ELSE NULL 
    END AS credited_percentage,
    CASE 
        WHEN cd.company_count IS NULL THEN 'No Company'
        ELSE 'Company Present'
    END AS company_status
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompleteCast cc ON rm.movie_id = cc.movie_id
WHERE 
    rm.rank_year <= 10
ORDER BY 
    rm.production_year DESC, rm.movie_id;
