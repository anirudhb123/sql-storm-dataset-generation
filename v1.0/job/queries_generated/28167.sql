WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        m.id, m.title, m.production_year
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), MovieCompanies AS (
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
    rm.movie_title,
    rm.production_year,
    rm.actor_count,
    rm.cast_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.companies, 'No Companies') AS companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
