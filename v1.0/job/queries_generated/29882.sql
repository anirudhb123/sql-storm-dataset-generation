WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%'
),

CastDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(CONCAT_WS(' ', a.name, a.surname), ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),

CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keyword,
    cd.cast_names,
    ci.company_names,
    ci.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC;
