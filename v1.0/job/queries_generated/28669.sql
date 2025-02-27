WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS also_known_as,
        ROUND(AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 2) AS average_roles
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    GROUP BY 
        m.id
    ORDER BY 
        cast_count DESC
    LIMIT 50
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
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.also_known_as,
    mk.keywords,
    mc.companies,
    rm.average_roles
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
