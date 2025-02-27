WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.company_name, 'No Company') AS company_name,
    COALESCE(cd.company_type, 'Unknown') AS company_type,
    COALESCE(cd.total_companies, 0) AS total_companies,
    COALESCE(cd.total_companies, 0) * 1.0 / NULLIF(cd.total_companies, 0) AS comp_ratio,
    COALESCE(ca.num_actors, 0) AS num_actors,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CastDetails ca ON rm.movie_id = ca.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
