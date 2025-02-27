WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        MAX(ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
CompleteCast AS (
    SELECT 
        cc.movie_id,
        GROUP_CONCAT(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast_list
    FROM 
        complete_cast cc
    JOIN 
        aka_name a ON cc.subject_id = a.id
    JOIN 
        role_type r ON cc.role_id = r.id
    GROUP BY 
        cc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    mk.keywords,
    mc.companies,
    mc.company_types,
    cc.cast_list
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    CompleteCast cc ON rm.movie_id = cc.movie_id
WHERE 
    rm.title_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
