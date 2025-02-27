WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY t.id) AS avg_has_note
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        complete_cast cc ON t.movie_id = cc.movie_id
    LEFT JOIN 
        info_type it ON it.id = cc.status_id
    WHERE 
        t.production_year IS NOT NULL AND
        t.production_year >= 2000
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
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    mk.keywords,
    cd.company_name,
    cd.company_type,
    cd.total_companies,
    CASE 
        WHEN rm.avg_has_note > 0.5 THEN 'Has Notes' 
        ELSE 'No Notable Notes' 
    END AS notes_status
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.total_cast > 5 OR cd.total_companies > 1
ORDER BY 
    rm.production_year DESC, rm.title;
