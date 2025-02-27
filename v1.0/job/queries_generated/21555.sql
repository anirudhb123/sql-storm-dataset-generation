WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS ranking
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(NULLIF(m.note, ''), 'N/A') AS company_note
    FROM 
        movie_companies m 
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL AND c.country_code <> ''
),
CompleteCastInfo AS (
    SELECT 
        cc.movie_id,
        STRING_AGG(CONCAT_WS(' as ', n.name, rt.role), ', ') AS cast_details
    FROM 
        complete_cast cc
    JOIN 
        name n ON cc.subject_id = n.id
    JOIN 
        role_type rt ON cc.status_id = rt.id
    GROUP BY 
        cc.movie_id
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
FlexibleInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CASE 
            WHEN info_type.info IS NULL THEN 'Unknown Info' 
            ELSE CONCAT_WS(': ', info_type.info, mi.info) 
        END, '; ') AS info_collection
    FROM 
        movie_info mi
    JOIN 
        info_type ON mi.info_type_id = info_type.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.company_name, 'Independent') AS producing_company,
    COALESCE(cd.company_type, 'Unknown') AS type,
    COALESCE(cc.cast_details, 'No Cast') AS cast,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(fi.info_collection, 'No Information') AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompleteCastInfo cc ON rm.movie_id = cc.movie_id
FULL OUTER JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    FlexibleInfo fi ON rm.movie_id = fi.movie_id
WHERE 
    (rm.ranking <= 10 OR rm.production_year > 2000)
ORDER BY 
    rm.production_year DESC, rm.title ASC
LIMIT 50;
