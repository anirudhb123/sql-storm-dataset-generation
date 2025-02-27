WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
CompanyDetails AS (
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
DetailedMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        mk.keywords,
        cd.company_name,
        cd.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = rm.id
    LEFT JOIN 
        CompanyDetails cd ON cd.movie_id = rm.id
)
SELECT 
    dm.title,
    dm.production_year,
    COALESCE(dm.keywords, '{No Keywords}') AS keywords,
    dm.company_name,
    dm.company_type
FROM 
    DetailedMovies dm 
WHERE 
    dm.year_rank <= 5 
ORDER BY 
    dm.production_year DESC, 
    dm.title;
