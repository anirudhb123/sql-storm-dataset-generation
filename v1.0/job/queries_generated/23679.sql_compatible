
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rn,
        COUNT(c.person_id) AS total_cast
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
HighCastMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.total_cast > 5
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        STRING_AGG(ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
CompleteDetails AS (
    SELECT 
        hcm.movie_id,
        hcm.title,
        hcm.production_year,
        hcm.total_cast,
        km.keywords,
        cd.companies,
        cd.company_types
    FROM 
        HighCastMovies hcm
    LEFT JOIN 
        MovieKeywords km ON hcm.movie_id = km.movie_id
    LEFT JOIN 
        CompanyDetails cd ON hcm.movie_id = cd.movie_id
)
SELECT 
    cd.title,
    cd.production_year,
    cd.total_cast,
    COALESCE(cd.keywords, ARRAY[]::VARCHAR[]) AS keywords,
    COALESCE(cd.companies, ARRAY[]::VARCHAR[]) AS companies,
    COALESCE(cd.company_types, '') AS company_types
FROM 
    CompleteDetails cd
WHERE 
    cd.total_cast > (SELECT AVG(total_cast) FROM HighCastMovies)
ORDER BY 
    cd.production_year DESC, cd.total_cast DESC
LIMIT 10;
