WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM 
        title m
    WHERE 
        m.production_year IS NOT NULL
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
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
    fc.company_name,
    fc.company_type,
    mk.keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = rm.movie_id) AS total_cast,
    (SELECT COUNT(*) FROM aka_title at WHERE at.movie_id = rm.movie_id) AS total_aliases
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCompanies fc ON rm.movie_id = fc.movie_id AND fc.company_rank = 1
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    mk.keywords IS NOT NULL
OR 
    (rm.production_year > 2000 AND fc.company_type = 'Distributor')
ORDER BY 
    rm.production_year DESC, 
    rm.title;
