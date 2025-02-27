WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS average_order,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COMPANY.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name COMPANY ON mc.company_id = COMPANY.id
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
    rm.cast_count,
    rm.average_order,
    rm.aliases,
    cm.company_name,
    cm.company_type,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
